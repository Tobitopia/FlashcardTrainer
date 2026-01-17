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

  /// Helper method to upload a file to Cloud Storage and get its URL
  Future<String?> _uploadMediaFile(String filePath, String setId) async {
    print("Starting upload for file: $filePath");
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print("Upload failed: No user logged in.");
      return null;
    }

    File file = File(filePath);
    if (!await file.exists()) {
      print("Upload skipped: File does not exist at path: $filePath");
      return null;
    }

    String fileName = p.basename(file.path);
    String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    String storagePath = 'uploads/$setId/$uniqueFileName';

    try {
      Reference ref = _storage.ref().child(storagePath);
      print("Uploading to Storage path: $storagePath");
      
      UploadTask uploadTask = ref.putFile(file);
      
      // Wait for completion
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print("Upload successful. Download URL: $downloadUrl");
      return downloadUrl;
    } on FirebaseException catch (e) {
      print("Firebase Storage error during upload: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("Unexpected error during storage upload: $e");
      return null;
    }
  }

  Future<String?> uploadOrUpdateVocabSet(VocabSet vocabSet, {String? existingCloudId}) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print("No user logged in to upload/update a set.");
      return null;
    }

    try {
      final CollectionReference setsCollection = _firestore.collection('sets');
      DocumentReference setDocRef;

      if (existingCloudId != null) {
        setDocRef = setsCollection.doc(existingCloudId);
        await setDocRef.update({
          'ownerId': currentUser.uid,
          'ownerEmail': currentUser.email,
          'setName': vocabSet.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'visibility': vocabSet.visibility.index,
        });

        // Delete only cards owned by current user
        QuerySnapshot currentCards = await setDocRef.collection('cards').where('ownerId', isEqualTo: currentUser.uid).get();
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
        });
      }

      CollectionReference cardsCollection = setDocRef.collection('cards');
      for (VocabCard card in vocabSet.cards) {
        String? mediaUrl = card.mediaPath;
        
        if (mediaUrl != null && !mediaUrl.startsWith('http')) {
          print("Local media detected, initiating upload...");
          mediaUrl = await _uploadMediaFile(mediaUrl, setDocRef.id);
        }

        await cardsCollection.add({
          'title': card.title,
          'description': card.description,
          'labels': card.labels,
          'rating': card.rating,
          'ownerId': currentUser.uid,
          'visibility': vocabSet.visibility.index,
          if (mediaUrl != null) 'mediaUrl': mediaUrl,
        });
      }

      print('Set upload/update process complete! Set ID: ${setDocRef.id}');
      return setDocRef.id;
    } catch (e) {
      print('Error in uploadOrUpdateVocabSet: $e');
      return null;
    }
  }

  Future<VocabSet?> downloadVocabSet(String setId) async {
    print("Attempting to download set with ID: $setId");
    final User? currentUser = _auth.currentUser;

    try {
      DocumentSnapshot setDoc = await _firestore.collection('sets').doc(setId).get();
      if (!setDoc.exists) {
        print('No set found with ID: $setId');
        return null;
      }

      final setData = setDoc.data() as Map<String, dynamic>;
      final set = VocabSet(
        name: setData['setName'],
        cloudId: setDoc.id,
        isSynced: true,
        visibility: Visibility.values[setData['visibility'] ?? 0],
      );

      // Perform specific queries to satisfy security rules
      final publicCardsQuery = _firestore
          .collection('sets').doc(setId).collection('cards')
          .where('visibility', whereIn: [1, 2])
          .get();

      Future<QuerySnapshot<Map<String, dynamic>>>? userCardsQuery;
      if (currentUser != null) {
        userCardsQuery = _firestore
            .collection('sets').doc(setId).collection('cards')
            .where('ownerId', isEqualTo: currentUser.uid)
            .get();
      }
      
      final results = await Future.wait([
        publicCardsQuery,
        if (userCardsQuery != null) userCardsQuery,
      ]);

      final allCardDocs = <String, QueryDocumentSnapshot>{};
      for (var doc in (results[0] as QuerySnapshot).docs) {
        allCardDocs[doc.id] = doc;
      }
      if (results.length > 1) {
        for (var doc in (results[1] as QuerySnapshot).docs) {
          allCardDocs[doc.id] = doc;
        }
      }

      for (var cardDoc in allCardDocs.values) {
        final cardData = cardDoc.data() as Map<String, dynamic>;
        set.addCard(VocabCard(
          title: cardData['title'],
          description: cardData['description'],
          labels: List<String>.from(cardData['labels'] ?? []),
          rating: cardData['rating'] ?? 0,
          mediaPath: cardData['mediaUrl'],
        ));
      }

      print("Set download successful. Cards found: ${allCardDocs.length}");
      return set;
    } on FirebaseException catch (e) {
      print('Firebase error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error: $e');
      return null;
    }
  }
}
