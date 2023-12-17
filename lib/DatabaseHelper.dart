import 'package:cloud_firestore/cloud_firestore.dart';

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
    QuerySnapshot querySnapshot = await _firestore.collection('items').get();
    return querySnapshot.docs
        .map((doc) => ItemModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Update operation
  Future<void> updateItem(
      String itemId, Map<String, dynamic> updatedData) async {
    print('Updating item $itemId with data $updatedData');

    // Convert the int ID to a String
    String documentId = itemId.toString();

    // Use the String ID to update the document
    await _firestore.collection('items').doc(documentId).update(updatedData);

    print('Update completed');
  }

  // Delete operation // TODO: Overload versions of this
  Future<void> deleteItem(String itemId) async {
    await _firestore.collection('items').doc(itemId).delete();
  }
}
