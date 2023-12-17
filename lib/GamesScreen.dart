import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({Key? key}) : super(key: key);

  @override
  _GamesScreenState createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final DatabaseReference databaseReference =
      FirebaseDatabase.instance.ref().child('draggableItems');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Game with Firebase'),
      ),
      body: FirebaseAnimatedList(
        query: databaseReference,
        itemBuilder: (BuildContext context, DataSnapshot snapshot,
            Animation<double> animation, int index) {
          final Map<dynamic, dynamic>? values = snapshot.value as Map?;
          if (values == null) return Container();

          final double top = values['top']?.toDouble() ?? 0.0;
          final double left = values['left']?.toDouble() ?? 0.0;
          final String color = values['color'] as String? ?? 'blue';

          return Positioned(
            top: top,
            left: left,
            child: Draggable(
              childWhenDragging: Container(),
              feedback: Container(
                width: 50.0,
                height: 50.0,
                color: const Color(0x00000001),
              ),
              child: Container(
                width: 50.0,
                height: 50.0,
                color: const Color(0x00000001),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add a new draggable box
          addDraggableItem();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void addDraggableItem() {
    // Add data to Firebase Realtime Database
    databaseReference.push().set({
      'top': 50.0,
      'left': 50.0,
      'color': 'blue',
    });
  }
}
