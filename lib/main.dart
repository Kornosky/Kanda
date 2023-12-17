import 'dart:io';

import 'package:flutter/material.dart';

import 'DatabaseHelper.dart';
import 'EditItemPage.dart';
import 'ItemModel.dart';
import 'MyApp.dart';

void main() {
  runApp(MyApp());
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final dbHelper = DatabaseHelper();
  List<ItemModel> items = []; // Your list of items

  @override
  void initState() {
    super.initState();
    // Load items from the database or initialize the list as needed
    loadItems();
  }

  // Function to load items from the database
  Future<void> loadItems() async {
    List<ItemModel> loadedItems = await dbHelper.getAllItems();
    setState(() {
      items = loadedItems;
    });
  }

// In your main page
  Future<void> editItem(ItemModel item) async {
    // Use await to wait for the completion of the navigation
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditItemPage(item: item, dbHelper: dbHelper),
      ),
    );

    // After the navigation is complete, load items from the database again to refresh the list
    await loadItems();
  }

// Function to add a new item
  void addItem() async {
    // Retrieve the highest existing ID from the database
    List<ItemModel> existingItems = await dbHelper.getAllItems();
    int maxId = existingItems.isEmpty
        ? 0
        : existingItems.map((item) => item.id).reduce((a, b) => a > b ? a : b);

    // Generate the new ID by incrementing the highest existing ID
    int newId = maxId + 1;

    // Add a new item with the generated ID and other default values
    ItemModel newItem = ItemModel(
      id: newId,
      title: 'New Item',
      date: DateTime.now().millisecondsSinceEpoch,
      isSelected: false,
      description: 'Description for the new item',
      imagePath: null,
    );

    // Insert the item into the database
    await dbHelper.insertItem(newItem);

    // Load items from the database again to refresh the list
    await loadItems();

    // Initiate the edit item operation/screen after the item is added
    await editItem(newItem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kanda'),
      ),
      body: FutureBuilder<List<ItemModel>>(
        future: dbHelper.getAllItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('No items found.');
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                ItemModel item = snapshot.data![index];

                // Calculate the difference between the current date and the item's date
                Duration difference = DateTime.now()
                    .difference(DateTime.fromMillisecondsSinceEpoch(item.date));

                String formattedDate;

                if (difference.isNegative) {
                  // The item's date is in the future
                  formattedDate = '${difference.inDays.abs()} days until';
                } else {
                  // The item's date is in the past
                  formattedDate = '${difference.inDays} days ago';
                }

                return ListTile(
                  title: Text(item.title),
                  subtitle: Text(item.description ?? ''),
                  trailing: Text(formattedDate),
                  leading: item.imagePath != null &&
                          File(item.imagePath!).existsSync()
                      ? SizedBox(
                          width: 56.0, // Adjust the width as needed
                          height: 56.0, // Adjust the height as needed
                          child: Image.file(
                            File(item.imagePath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : null,
                  onTap: () {
                    editItem(item);
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Call the function to add a new item
          addItem();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
