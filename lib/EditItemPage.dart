import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Import this for date formatting

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
              child: _pickedImage != null &&
                      (!kIsWeb && File(_pickedImage!.path).existsSync())
                  ? Image.file(
                      _pickedImage!,
                      fit: BoxFit.cover,
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

  // Method to pick an image using the image_picker package
  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  // Method to delete the item
  void deleteItem() {
    // Delete the item from the database using widget.dbHelper
    //TODO allow deletion if it doesn't exist on database
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
      imagePath: _pickedImage?.path,
    );

    // Update the item in the database using widget.dbHelper
    // Assume doc id will be available by this point
    widget.dbHelper.updateItem(updatedItem.id!, updatedItem.toMap());

    Navigator.pop(context);
  }
}
