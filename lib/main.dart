import 'dart:io';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//If you just want the latest
import 'package:timezone/data/latest.dart' as tzlatest;
import 'package:timezone/timezone.dart' as tz;

import 'ChatScreen.dart';
import 'DatabaseHelper.dart';
import 'EditItemPage.dart';
import 'GamesScreen.dart';
import 'ItemDetailsScreen.dart';
import 'ItemModel.dart';
import 'MyApp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  runApp(MyApp());
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final dbHelper = DatabaseHelper();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<ItemModel> items = []; // Your list of items

  @override
  void initState() {
    super.initState();

    // Load items from the database or initialize the list as needed
    loadItems();
    // Initialize notifications
    initializeNotifications();
    scheduleRandomNotification();
    // flutterLocalNotificationsPlugin.cancelAll();
  }

  void initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // ,
    // onSelectNotification: (String? payload) async {
    // // Handle notification tap
    // },
  }

  Future<void> scheduleNotification(ItemModel item) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // Replace with your own channel ID
      'your_channel_name', // Replace with your own channel name
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    tzlatest.initializeTimeZones();
    // Convert millisecondsSinceEpoch to TZDateTime
    tz.TZDateTime itemDate = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.local, // Replace with the desired time zone
      item.date,
    );
    // Subtract one day from the item date
    tz.TZDateTime notificationDate = itemDate.subtract(const Duration(days: 1));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      item.id,
      item.title,
      item.description, //TODO: make this more interesting
      notificationDate, // Schedule notification 1 day before the item date
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    // Show the notification immediately (if you want to)
    await flutterLocalNotificationsPlugin.show(
      item.id,
      item.title,
      item.description, // TODO: make this more interesting
      platformChannelSpecifics,
      payload: 'Not present',
    );
  }

  Future<void> scheduleRandomNotification() async {
    // Get a random item from the database
    if (items.isNotEmpty) {
      ItemModel randomItem = items[Random().nextInt(items.length)];

      // // Convert DateTime to TZDateTime
      // tz.TZDateTime scheduledTime = tz.TZDateTime.fromMillisecondsSinceEpoch(
      //   tz.getLocation('UTC'), // Replace with the desired time zone
      //   randomItem.date,
      // );
      // Get the current time
      DateTime now = DateTime.now();
      // Calculate the scheduled time, which is 1 minute from now
      DateTime scheduledTime = now.add(const Duration(minutes: 1));
      // Convert DateTime to TZDateTime
      tz.TZDateTime scheduledTZTime = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      // Create notification details
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'random_channel_id',
        'Random Channel Name',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: false,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      // Schedule the notification for the random item
      await flutterLocalNotificationsPlugin.zonedSchedule(
        randomItem.id,
        randomItem.title,
        randomItem.description, //TODO: make this more interesting
        scheduledTZTime,
        platformChannelSpecifics,
        // androidScheduleMode: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      // Show the notification immediately (if you want to)
      await flutterLocalNotificationsPlugin.show(
        randomItem.id,
        randomItem.title,
        randomItem.description, // TODO: make this more interesting
        platformChannelSpecifics,
        payload: 'Not present',
      );
    }
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

    // Schedule a notification for the new item
    await scheduleNotification(newItem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanda'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Menu'),
            ),
            ListTile(
              title: const Text('Chat'),
              onTap: () {
                // Navigate to the Chat screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Games'),
              onTap: () {
                // Navigate to the Games screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GamesScreen()),
                );
              },
              // Add more menu items as needed
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<ItemModel>>(
        future: dbHelper.getAllItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text('No items found.');
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
                  onLongPress: () {
                    editItem(item);
                  },
                  onTap: () {
                    // Navigate to a new screen to show item details
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailsScreen(item: item),
                      ),
                    );
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
