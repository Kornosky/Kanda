import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import 'ItemModel.dart';

class DatabaseHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create operation
  Future<ItemModel> addItem() async {
    // Create an ItemModel instance with the added item's data
    ItemModel newItem = ItemModel(
      title: 'New Item',
      date: DateTime.now().millisecondsSinceEpoch,
      isSelected: false,
      description: 'Description for the new item',
      imagePath: null,
      userId:
          FirebaseAuth.instance.currentUser?.uid, // Include the UID of the user
    );

    // Add the item to Firestore
    DocumentReference documentReference =
        await _firestore.collection('items').add(newItem.toMap());

    // Get the auto-generated document ID
    String documentId = documentReference.id;

    // Update the item in Firestore to store the document ID
    await documentReference.update({'id': documentId});

    newItem.id = documentId;

    return newItem;
  }

  // Insert operation with the Firestore-assigned ID returned
  Future<String> insertItem(Map<String, dynamic> itemData) async {
    DocumentReference docRef =
        await _firestore.collection('items').add(itemData);

    // Return the Firestore-assigned document ID
    return docRef.id;
  }

  // Read operation
  Future<List<ItemModel>> getAllItems() async {
    // Get the current user from FirebaseAuth
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;

      QuerySnapshot querySnapshot = await _firestore
          .collection('items')
          .where('userId', isEqualTo: userId) // Filter by userId
          .get();

      return querySnapshot.docs
          .map((doc) => ItemModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } else {
      // Handle the case where the user is not signed in
      return [];
    }
  }

  // Update operation
  Future<void> updateItem(
      String itemId, Map<String, dynamic> updatedData) async {
    // Convert the int ID to a String
    String documentId = itemId.toString();

    // Use the String ID to update the document
    await _firestore.collection('items').doc(documentId).update(updatedData);
  }

  // Delete operation // TODO: Overload versions of this
  Future<void> deleteItem(String itemId) async {
    await _firestore.collection('items').doc(itemId).delete();
  }

  static Future<String?> uploadImageToFirebaseStorage(File pickedImage) async {
    final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    var userID = FirebaseAuth.instance.currentUser?.uid;
    final Reference ref = FirebaseStorage.instance
        .ref()
        .child('images/itemImages/$userID/$fileName.jpg');

    try {
      if (kIsWeb) {
        await ref
            .putData(
          await pickedImage.readAsBytes(),
          SettableMetadata(contentType: 'image/jpeg'),
        )
            .whenComplete(() async {
          return await ref.getDownloadURL();
        });
      } else {
        await ref.putFile(pickedImage);
        return await ref.getDownloadURL();
      }
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<bool> isImageAlreadyUploaded(File imageFile) async {
    // Check if the image file is already in the cache
    // if (imageCache.containsKey(imageFile.path)) {
    //   return true;
    // }
    var userID = FirebaseAuth.instance.currentUser?.uid;

    // If not in cache, check Firebase Storage
    final String fileName = path.basenameWithoutExtension(imageFile.path);
    final Reference ref = FirebaseStorage.instance
        .ref()
        .child('images/itemImages/$userID/$fileName.jpg');

    try {
      // Attempt to get the download URL
      String downloadURL = await ref.getDownloadURL();
      // Cache the download URL
      // imageCache[imageFile.path] = downloadURL;
      return true;
    } catch (e) {
      // If the object does not exist, return false
      return false;
    }
  }
}
