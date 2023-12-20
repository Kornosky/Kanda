import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Import this for date formatting
import 'package:path/path.dart' as path;

import 'DatabaseHelper.dart';
import 'ItemModel.dart';

class EditItemPage extends StatefulWidget {
  final ItemModel item;
  final DatabaseHelper dbHelper;

  EditItemPage({required this.item, required this.dbHelper});

  @override
  _EditItemPageState createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late DateTime selectedDate; // Variable to store the selected date
  File? _pickedImage; // Variable to store the picked image file

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.item.title);
    descriptionController =
        TextEditingController(text: widget.item.description ?? '');
    selectedDate = DateTime.fromMillisecondsSinceEpoch(widget.item.date);
    _pickedImage =
        widget.item.imagePath != null ? File(widget.item.imagePath!) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Title'),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Enter title',
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Description'),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                hintText: 'Enter description',
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Date'),
            ElevatedButton(
              onPressed: () {
                // Show date picker and update the selectedDate
                pickDate();
              },
              child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
            ),
            // Display the picked image if available
            SizedBox(
              width: 240.0,
              height: 240.0,
              child: _pickedImage != null && _pickedImage!.path.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _pickedImage!.path,
                      fit: BoxFit.cover,
                      width: double.infinity, // Adjust to your layout needs
                      height: double.infinity, // Adjust to your layout needs
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(Icons.error),
                      ),
                    )
                  : Container(),
            ),

            const SizedBox(height: 16.0),

            // Button to pick an image
            ElevatedButton(
              onPressed: () {
                // Show image picker
                pickImage();
              },
              child: const Text('Pick Image'),
            ),
            // Delete button
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Save the edited item
                saveChanges();
              },
              child: const Text('Save Changes'),
            ),

            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Prompt the user before deleting
                showDeleteConfirmationDialog();
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.red, // Use red color for delete button
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  // Method to show a confirmation dialog before deleting
  Future<void> showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Perform the delete action and close the dialog
                deleteItem();
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Todo: Store this in app cache data for use across views
  Map<String, String> imageCache = {}; // Map to store image download URLs

  // Pick image and just set it as the current image for display purposes
  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    var image = null;
    if (pickedFile != null) {
      String filePath = pickedFile.path;

      // Check if the image is already in the cache
      if (imageCache.containsKey(filePath)) {
        image = File(filePath);
      } else {
        if (kIsWeb) {
          final response = await http.get(Uri.parse(filePath));
          final List<int> bytes = response.bodyBytes;
          image = File.fromRawPath(Uint8List.fromList(bytes));
        } else {
          image = File(filePath);
        }
      }

      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<String?> uploadImageToFirebaseStorage(File pickedImage) async {
    // Only concern is uploading to database and return the database path for future retrieval
    final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    var userID = FirebaseAuth.instance.currentUser?.uid;
    final Reference ref = FirebaseStorage.instance
        .ref()
        .child('images/itemImages/$userID/$fileName.jpg');

    if (await isImageAlreadyUploaded(pickedImage!)) {
      // Image is already uploaded, no need to re-upload
      return imageCache[pickedImage!.path];
    }

    if (kIsWeb) {
      // Upload
      await ref
          .putData(
        await pickedImage!.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      )
          .whenComplete(() async {
        await ref.getDownloadURL().then((value) {
          imageCache[pickedImage!.path] = value;
        });
      });
    } else {
      await ref.putFile(pickedImage!);
      // Get the URL of the uploaded image
      String downloadURL = await ref.getDownloadURL();
      imageCache[pickedImage!.path] = downloadURL;
    }

    return imageCache[pickedImage!.path];
  }

  Future<bool> isImageAlreadyUploaded(File imageFile) async {
    // Check if the image file is already in the cache
    if (imageCache.containsKey(imageFile.path)) {
      return true;
    }
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
      imageCache[imageFile.path] = downloadURL;
      return true;
    } catch (e) {
      // If the object does not exist, return false
      return false;
    }
  }

  // Method to delete the item
  void deleteItem() {
    // Delete the item from the database using widget.dbHelper
    //TODO allow deletion if it doesn't exist on databasee
    widget.dbHelper.deleteItem(widget.item.id!);

    // Navigate back to the previous screen
    Navigator.pop(context);
  }

  void saveChanges() {
    String editedTitle = titleController.text;
    String editedDescription = descriptionController.text;

    ItemModel updatedItem = widget.item.copyWith(
      title: editedTitle,
      description: editedDescription,
      date: selectedDate.millisecondsSinceEpoch,
    );

    // If an image is picked and we are not on the web
    if (_pickedImage != null && !kIsWeb) {
      // Start uploading the image to Firebase Storage
      Future<String?> uploadTask = uploadImageToFirebaseStorage(_pickedImage!);

      // Continue with other operations while the image is uploading
      uploadTask.then((downloadURL) {
        if (downloadURL != null) {
          // If the download URL is available, update the item
          updatedItem = updatedItem.copyWith(imagePath: downloadURL);
          widget.dbHelper.updateItem(updatedItem.id!, updatedItem.toMap());

          // Pop the navigator when everything is done
          Navigator.pop(context);
        } else {
          // Handle the case where download URL is null
          print('Download URL is null. Handle accordingly.');
        }
      }).catchError((error) {
        // Handle errors during the upload
        print('Error during upload: $error');
      });
    } else {
      // If no image is picked or on the web, update the item directly
      widget.dbHelper.updateItem(updatedItem.id!, updatedItem.toMap());

      // Pop the navigator when everything is done
      Navigator.pop(context);
    }
  }
}
