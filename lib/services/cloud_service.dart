import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:path/path.dart' as p;
import 'package:projects/models/visibility.dart';

class CloudService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<String>> fetchAllUserSetIds() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final ownedQuery = await _firestore.collection('sets')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      final collaboratorQuery = await _firestore.collection('sets')
          .where('collaborators.${user.uid}', whereIn: ['editor', 'viewer'])
          .get();

      final allIds = <String>{};
      for (var doc in ownedQuery.docs) {
        allIds.add(doc.id);
      }
      for (var doc in collaboratorQuery.docs) {
        allIds.add(doc.id);
      }

      return allIds.toList();
    } catch (e) {
      print("Error fetching user sets: $e");
      return [];
    }
  }

  Future<bool> joinVocabSet(String setId, String role) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      DocumentReference setRef = _firestore.collection('sets').doc(setId);
      await setRef.update({
        'collaborators.${user.uid}': role,
      });
      return true;
    } catch (e) {
      print("Error joining set: $e");
      return false;
    }
  }

  Future<String?> _uploadMediaFile(String filePath, String setId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    File file = File(filePath);
    if (!await file.exists()) return null;

    String fileName = p.basename(file.path);
    String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    String storagePath = 'uploads/$setId/$uniqueFileName';

    try {
      Reference ref = _storage.ref().child(storagePath);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Storage upload error: $e");
      return null;
    }
  }

  Future<String?> uploadOrUpdateVocabSet(VocabSet vocabSet, {String? existingCloudId}) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      final CollectionReference setsCollection = _firestore.collection('sets');
      DocumentReference setDocRef;

      if (existingCloudId != null) {
        setDocRef = setsCollection.doc(existingCloudId);
        await setDocRef.update({
          'setName': vocabSet.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'visibility': vocabSet.visibility.index,
          'isProgression': vocabSet.isProgression,
        });

        QuerySnapshot currentCards = await setDocRef.collection('cards').get();
        for (DocumentSnapshot doc in currentCards.docs) {
          await doc.reference.delete();
        }
      } else {
        setDocRef = setsCollection.doc();
        await setDocRef.set({
          'ownerId': currentUser.uid,
          'ownerEmail': currentUser.email,
          'setName': vocabSet.name,
          'createdAt': FieldValue.serverTimestamp(),
          'visibility': vocabSet.visibility.index,
          'isProgression': vocabSet.isProgression,
          'collaborators': {}, 
        });
      }

      CollectionReference cardsCollection = setDocRef.collection('cards');
      for (VocabCard card in vocabSet.cards) {
        String? mediaUrl = card.remoteUrl; 

        if (mediaUrl == null && card.mediaPath != null) {
           mediaUrl = await _uploadMediaFile(card.mediaPath!, setDocRef.id);
        }

        await cardsCollection.add({
          'title': card.title,
          'description': card.description,
          'labels': card.labels,
          'rating': card.rating,
          'ownerId': currentUser.uid, 
          'visibility': vocabSet.visibility.index,
          'createdAt': card.createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
          if (mediaUrl != null) 'mediaUrl': mediaUrl, 
        });
      }
      return setDocRef.id;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<VocabSet?> downloadVocabSet(String setId) async {
    final User? currentUser = _auth.currentUser;
    try {
      DocumentSnapshot setDoc = await _firestore.collection('sets').doc(setId).get();
      if (!setDoc.exists) return null;

      final setData = setDoc.data() as Map<String, dynamic>;
      
      String role = 'viewer';
      if (currentUser != null) {
        if (setData['ownerId'] == currentUser.uid) {
          role = 'owner';
        } else if (setData['collaborators'] != null && setData['collaborators'][currentUser.uid] != null) {
          role = setData['collaborators'][currentUser.uid];
        }
      }

      final set = VocabSet(
        name: setData['setName'],
        cloudId: setDoc.id,
        isSynced: true,
        visibility: Visibility.values[setData['visibility'] ?? 0],
        role: role,
        isProgression: setData['isProgression'] ?? false,
      );

      QuerySnapshot cardsSnapshot = await _firestore.collection('sets').doc(setId).collection('cards').orderBy('createdAt', descending: false).get();

      for (var cardDoc in cardsSnapshot.docs) {
        final cardData = cardDoc.data() as Map<String, dynamic>;
        set.addCard(VocabCard(
          title: cardData['title'],
          description: cardData['description'],
          labels: List<String>.from(cardData['labels'] ?? []),
          rating: cardData['rating'] ?? 0,
          remoteUrl: cardData['mediaUrl'], 
          mediaPath: null, 
          createdAt: cardData['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(cardData['createdAt']) : null,
        ));
      }
      return set;
    } catch (e) {
      print('Download error: $e');
      return null;
    }
  }

  // New method to completely remove a set from the cloud
  Future<bool> deleteVocabSet(String setId) async {
    try {
      // 1. Delete all cards in subcollection
      final cardsQuery = await _firestore.collection('sets').doc(setId).collection('cards').get();
      for (var doc in cardsQuery.docs) {
        await doc.reference.delete();
      }

      // 2. Delete the set document itself
      await _firestore.collection('sets').doc(setId).delete();

      // 3. Try to delete the storage folder (best effort)
      try {
        final listResult = await _storage.ref().child('uploads/$setId').listAll();
        for (var item in listResult.items) {
          await item.delete();
        }
      } catch (storageError) {
        print("Storage cleanup error (non-fatal): $storageError");
      }

      return true;
    } catch (e) {
      print("Error deleting set from cloud: $e");
      return false;
    }
  }
}
