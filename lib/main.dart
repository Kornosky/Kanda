import 'dart:math';

import 'package:animate_gradient/animate_gradient.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as fireBaseAppCheck;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
//If you just want the latest
import 'package:timezone/data/latest.dart' as tzlatest;
import 'package:timezone/timezone.dart' as tz;

import 'DatabaseHelper.dart';
import 'EditItemPage.dart';
import 'ItemModel.dart';
import 'MyApp.dart';
import 'ThemeData.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kIsWeb) {
    // await fireBaseAppCheck.FirebaseAppCheck.instance
    //     .activate(webRecaptchaSiteKey: 'YOUR_RECAPTCHA_SITE_KEY');
  } else {
    await fireBaseAppCheck.FirebaseAppCheck.instance.activate();
  }

  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
    PhoneAuthProvider(),
    GoogleProvider(
        clientId:
            "411167207929-qbkkg8n62a198b8r4hh41bjq4j65g0o5.apps.googleusercontent.com"),
    AppleProvider(),
  ]);
  AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      null,
      [
        NotificationChannel(
            channelGroupKey: 'basic_channel_group',
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: Color(0xFF9D50DD),
            ledColor: Colors.white)
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'basic_channel_group',
            channelGroupName: 'Basic group')
      ],
      debug: true);

  runApp(MyApp());
}

// Define enum for sorting options
enum SortOption { dateAdded, itemDate, random, deleteAll }

class MyHomePage extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String name = 'Awesome Notifications - Example App';
  static const Color mainColor = Colors.deepPurple;

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

  void initializeNotifications() async {
    // Check permissions
    // TODO: add dialogue
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        // This is just a basic example. For real apps, you must show some
        // friendly dialog box before call the request method.
        // This is very important to not harm the user experience
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    // Only after at least the action method is set, the notification events are delivered
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod:
            NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:
            NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:
            NotificationController.onDismissActionReceivedMethod);
  }

  Future<void> scheduleNotification(ItemModel item) async {
    AwesomeNotifications().createNotification(
        content: NotificationContent(
      id: 10,
      channelKey: 'basic_channel',
      actionType: ActionType.Default,
      title: 'Hello World!',
      body: 'This is my first notification!',
    ));

    tzlatest.initializeTimeZones();
    // Convert millisecondsSinceEpoch to TZDateTime
    tz.TZDateTime itemDate = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.local, // Replace with the desired time zone
      item.date,
    );
    // Subtract one day from the item date
    tz.TZDateTime notificationDate = itemDate.subtract(const Duration(days: 1));
  }

  Future<void> scheduleRandomNotification() async {
    // Get a random item from the database
    if (items.isNotEmpty) {
      ItemModel randomItem = items[Random().nextInt(items.length)];

      String localTimeZone =
          await AwesomeNotifications().getLocalTimeZoneIdentifier();
      String utcTimeZone =
          await AwesomeNotifications().getLocalTimeZoneIdentifier();
      await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 3,
            channelKey: 'basic_channel',
            title: randomItem.title,
            body: randomItem.description,
            payload: {'id': randomItem.id},
          ),
          schedule: NotificationInterval(
              interval: 60 * 60 * 24, timeZone: localTimeZone, repeats: true));
    }
  }

  // Function to load items from the database
  Future<void> loadItems() async {
    List<ItemModel> loadedItems = await dbHelper.getAllItems();
    setState(() {
      items = loadedItems;
    });

    // Initialize notifications
    initializeNotifications();
    scheduleRandomNotification();
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
    // Insert the item into the database and get the Firestore-assigned ID
    ItemModel newItem = await dbHelper.addItem();

    // Load items from the database again to refresh the list
    await loadItems();

    // Initiate the edit item operation/screen after the item is added
    await editItem(newItem);

    // Schedule a notification for the new item
    await scheduleNotification(newItem);
  }

  void deleteAllItems() {
    // Add your logic to delete all items from the database or data source
    // For example, you might use dbHelper.deleteAllItems();
    dbHelper.deleteItems(items);

    loadItems();
  }

  // Variable to store the current sorting option
  SortOption currentSortOption = SortOption.dateAdded;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: MediaQuery.of(context).platformBrightness == Brightness.dark
            ? darkTheme
            : lightTheme,
        navigatorKey: MyHomePage.navigatorKey,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Kanda'),
            actions: [
              // Add a PopupMenuButton for sorting and additional options
              PopupMenuButton<SortOption>(
                onSelected: (SortOption result) {
                  setState(() {
                    if (result == SortOption.deleteAll) {
                      // Handle the logic to delete all items
                      deleteAllItems();
                      currentSortOption = result;
                    } else {
                      // Handle sorting options
                      currentSortOption = result;
                    }
                  });
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<SortOption>>[
                  const PopupMenuItem<SortOption>(
                    value: SortOption.dateAdded,
                    child: Text('Sort by Date Added'),
                  ),
                  const PopupMenuItem<SortOption>(
                    value: SortOption.itemDate,
                    child: Text('Sort by Item Date'),
                  ),
                  const PopupMenuItem<SortOption>(
                    value: SortOption.random,
                    child: Text('Sort Randomly'),
                  ),
                  const PopupMenuDivider(), // Add a divider before the delete option
                  const PopupMenuItem<SortOption>(
                    value: SortOption.deleteAll,
                    child: Text('Delete All Items'),
                  ),
                ],
              ),
            ],
          ),
          body: Builder(
            builder: (context) => AnimateGradient(
              duration: Duration(seconds: 25),
              primaryColors: [
                Theme.of(context).primaryColor,
                Colors.pinkAccent,
              ],
              secondaryColors: [
                Theme.of(context).primaryColor,
                Colors.redAccent,
              ],
              child: FutureBuilder<List<ItemModel>>(
                future: dbHelper.getAllItems(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: const Text('No items found.'),
                    );
                  } else {
                    // Sort the data based on the selected option
                    List<ItemModel> sortedItems = snapshot.data!;
                    switch (currentSortOption) {
                      case SortOption.dateAdded:
                        // sortedItems.sort((a, b) => a.id.compareTo(b.id));
                        break;
                      case SortOption.itemDate:
                        sortedItems.sort((a, b) => a.date.compareTo(b.date));
                        break;
                      case SortOption.random:
                        // Implement random sorting logic
                        break;
                      default:
                        // Handle the case for SortOption.deleteAll or any other future values
                        // You can either leave it empty or provide a default sorting logic
                        break;
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        ItemModel item = snapshot.data![index];

                        // Calculate the difference between the current date and the item's date
                        Duration difference = DateTime.now().difference(
                          DateTime.fromMillisecondsSinceEpoch(item.date),
                        );

                        String formattedDate;

                        if (difference.isNegative) {
                          // The item's date is in the future
                          formattedDate =
                              '${difference.inDays.abs()} days until';
                        } else {
                          // The item's date is in the past
                          formattedDate = '${difference.inDays} days ago';
                        }

                        return ListTile(
                            // ... your existing ListTile code
                            );
                      },
                    );
                  }
                },
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Call the function to add a new item
              addItem();
            },
            child: const Icon(Icons.add),
          ),
        ));
  }
}

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here

    // Navigate into pages, avoiding to open the notification details page over another details page already opened
    MyHomePage.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/notification-page',
        (route) =>
            (route.settings.name != '/notification-page') || route.isFirst,
        arguments: receivedAction);
  }
}
