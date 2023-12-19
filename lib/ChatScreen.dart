import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:kanda/DatabaseHelper.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool showEmojiPicker = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat App'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }

                var messages = snapshot.data!.docs;

                List<Widget> messageWidgets = [];
                for (var message in messages) {
                  var messageData = message.data() as Map<String, dynamic>;
                  var messageText = messageData['text'];
                  var messageSender = messageData['sender'];
                  var imageUrl = messageData['image'];
                  var timestamp = messageData['timestamp'];

                  // Check if 'text' field exists in the message data
                  // Your existing code to handle text and image messages...
                  if (messageData.containsKey('text')) {
                    // Display the message text and sender in ListTile
                    var textWidget = ListTile(
                      subtitle: Text(
                        messageText ?? 'No Text',
                        style: TextStyle(
                            fontSize: 16), // Adjust the font size as needed
                      ),
                      title: Text(
                        '${messageSender ?? 'No Sender'}',
                        style: TextStyle(
                            fontSize: 10), // Adjust the font size as needed
                      ),
                    );
                    messageWidgets.add(textWidget);
                  } else {
                    var textWidget = ListTile(
                      title: Text(
                        '${messageSender ?? 'No Sender'}',
                        style: TextStyle(
                            fontSize: 10), // Adjust the font size as needed
                      ),
                    );
                    messageWidgets.add(textWidget);
                  }
                  if (imageUrl != null && imageUrl.isNotEmpty) {
                    // Display the image using Image.network
                    var imageWidget = Image.network(
                      imageUrl,
                      width: 100, // Adjust the width as needed
                      height: 100, // Adjust the height as needed
                    );
                    messageWidgets.add(imageWidget);
                  }
                }

                return ListView(
                  children: messageWidgets,
                );
              },
            ),
          ),
          if (showEmojiPicker)
            EmojiPicker(
              onEmojiSelected: (emoji, category) {
                // messageController.text = messageController.text + emoji.emoji;
              },
              textEditingController:
                  messageController, // pass here the same [TextEditingController] that is connected to your input field, usually a [TextFormField]
              config: Config(
                columns: 7,
                emojiSizeMax: 32 *
                    (foundation.defaultTargetPlatform == TargetPlatform.iOS
                        ? 1.30
                        : 1.0), // Issue: https://github.com/flutter/flutter/issues/28894
                verticalSpacing: 0,
                horizontalSpacing: 0,
                gridPadding: EdgeInsets.zero,
                initCategory: Category.RECENT,
                bgColor: Color(0xFFF2F2F2),
                indicatorColor: Colors.blue,
                iconColor: Colors.grey,
                iconColorSelected: Colors.blue,
                backspaceColor: Colors.blue,
                skinToneDialogBgColor: Colors.white,
                skinToneIndicatorColor: Colors.grey,
                enableSkinTones: true,
                recentTabBehavior: RecentTabBehavior.RECENT,
                recentsLimit: 28,
                noRecents: const Text(
                  'No Recents',
                  style: TextStyle(fontSize: 20, color: Colors.black26),
                  textAlign: TextAlign.center,
                ), // Needs to be const Widget
                loadingIndicator:
                    const SizedBox.shrink(), // Needs to be const Widget
                tabIndicatorAnimDuration: kTabScrollDuration,
                categoryIcons: const CategoryIcons(),
                buttonMode: ButtonMode.MATERIAL,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.emoji_emotions),
                  onPressed: () {
                    setState(() {
                      showEmojiPicker = !showEmojiPicker;
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    FirebaseFirestore.instance.collection('messages').add({
                      'text': messageController.text,
                      'sender': FirebaseAuth.instance.currentUser?.uid,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    messageController.clear();
                    scrollToBottom();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.camera),
                  onPressed: () {
                    pickImage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to scroll to the bottom
  void scrollToBottom() {
    //TODO: pass a scroll instance
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

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
        if (foundation.kIsWeb) {
          final response = await http.get(Uri.parse(filePath));
          final List<int> bytes = response.bodyBytes;
          image = File.fromRawPath(Uint8List.fromList(bytes));
        } else {
          image = File(filePath);
        }
      }
      String? uploadedPath =
          await DatabaseHelper.uploadImageToFirebaseStorage(image);

      if (uploadedPath == null) {
        // Handle the case where the upload failed
        // Display an error message and return or perform any other necessary actions
        print("Error uploading image. Please try again.");
        return;
      }

      FirebaseFirestore.instance.collection('messages').add({
        'image': uploadedPath,
        'sender': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      scrollToBottom();
    }
  }
}
