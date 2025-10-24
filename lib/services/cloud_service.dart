import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:path/path.dart' as p;

class CloudService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Helper method to upload a file to Cloud Storage and get its URL
  Future<String?> _uploadMediaFile(String filePath, String setId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    File file = File(filePath);
    if (!await file.exists()) {
      print("File to upload does not exist at path: $filePath");
      return null;
    }

    // Create a unique file name to avoid collisions in storage
    String fileName = p.basename(file.path);
    String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';

    try {
      // Create a reference to the location in Cloud Storage
      Reference ref = _storage.ref().child('uploads/${currentUser.uid}/$setId/$uniqueFileName');

      // Upload the file
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      // Get the public download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading media file: $e");
      return null;
    }
  }

  // New method: Handles both initial upload and updating an existing set
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
        // Update existing set
        setDocRef = setsCollection.doc(existingCloudId);
        await setDocRef.update({
          'ownerId': currentUser.uid,
          'ownerEmail': currentUser.email,
          'setName': vocabSet.name,
          'updatedAt': FieldValue.serverTimestamp(), // Add an update timestamp
        });
        // For simplicity, delete all existing cards and re-add them
        QuerySnapshot currentCards = await setDocRef.collection('cards').get();
        for (DocumentSnapshot doc in currentCards.docs) {
          await doc.reference.delete();
        }
      } else {
        // Upload new set
        setDocRef = setsCollection.doc();
        await setDocRef.set({
          'ownerId': currentUser.uid,
          'ownerEmail': currentUser.email,
          'setName': vocabSet.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      CollectionReference cardsCollection = setDocRef.collection('cards');
      for (VocabCard card in vocabSet.cards) {
        String? mediaUrl = card.mediaPath; // Start with current mediaPath
        
        // Only upload if it's a local file path (not an already uploaded URL)
        if (mediaUrl != null && !mediaUrl.startsWith('http')) {
          mediaUrl = await _uploadMediaFile(mediaUrl, setDocRef.id);
        }

        await cardsCollection.add({
          'title': card.title,
          'description': card.description,
          'labels': card.labels,
          'rating': card.rating,
          if (mediaUrl != null) 'mediaUrl': mediaUrl,
        });
      }

      print('Set uploaded/updated successfully! Set ID: ${setDocRef.id}');
      return setDocRef.id;
    } catch (e) {
      print('Error uploading/updating set: $e');
      return null;
    }
  }

  Future<VocabSet?> downloadVocabSet(String setId) async {
    try {
      DocumentSnapshot setDoc = await _firestore.collection('sets').doc(setId).get();
      if (!setDoc.exists) {
        print('No set found with ID: $setId');
        return null;
      }

      final set = VocabSet(name: setDoc['setName'], cloudId: setDoc.id, isSynced: true); // Include cloudId and set as synced
      QuerySnapshot cardsSnapshot = await _firestore.collection('sets').doc(setId).collection('cards').get();

      for (var cardDoc in cardsSnapshot.docs) {
        final cardData = cardDoc.data() as Map<String, dynamic>;
        set.addCard(VocabCard(
          title: cardData['title'],
          description: cardData['description'],
          labels: List<String>.from(cardData['labels'] ?? []),
          rating: cardData['rating'] ?? 0,
          mediaPath: cardData['mediaUrl'],
        ));
      }

      return set;
    } catch (e) {
      print('Error downloading set: $e');
      return null;
    }
  }
}
