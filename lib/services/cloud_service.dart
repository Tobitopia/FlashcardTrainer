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
  final FirebaseStorage _storage = FirebaseStorage.instance; // Add Firebase Storage instance

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

  Future<String?> uploadVocabSet(VocabSet vocabSet) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print("No user logged in to upload a set.");
      return null;
    }

    try {
      final CollectionReference setsCollection = _firestore.collection('sets');
      DocumentReference setDocRef = setsCollection.doc();

      Map<String, dynamic> setData = {
        'ownerId': currentUser.uid,
        'ownerEmail': currentUser.email,
        'setName': vocabSet.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await setDocRef.set(setData);

      CollectionReference cardsCollection = setDocRef.collection('cards');
      for (VocabCard card in vocabSet.cards) {
        String? mediaUrl;
        // If the card has a local media path, upload the file
        if (card.mediaPath != null && card.mediaPath!.isNotEmpty) {
          mediaUrl = await _uploadMediaFile(card.mediaPath!, setDocRef.id);
        }

        // Save the card data, including the new mediaUrl if it exists
        await cardsCollection.add({
          'title': card.title,
          'description': card.description,
          'labels': card.labels,
          'rating': card.rating,
          if (mediaUrl != null) 'mediaUrl': mediaUrl,
        });
      }

      print('Set uploaded successfully! Set ID: ${setDocRef.id}');
      return setDocRef.id;
    } catch (e) {
      print('Error uploading set: $e');
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

      final set = VocabSet(name: setDoc['setName']);
      QuerySnapshot cardsSnapshot = await _firestore.collection('sets').doc(setId).collection('cards').get();

      for (var cardDoc in cardsSnapshot.docs) {
        final cardData = cardDoc.data() as Map<String, dynamic>;
        set.addCard(VocabCard(
          title: cardData['title'],
          description: cardData['description'],
          labels: List<String>.from(cardData['labels'] ?? []),
          rating: cardData['rating'] ?? 0,
          // We now get the mediaUrl from Firestore
          mediaPath: cardData['mediaUrl'], // Temporarily store URL in mediaPath
        ));
      }

      return set;
    } catch (e) {
      print('Error downloading set: $e');
      return null;
    }
  }
}
