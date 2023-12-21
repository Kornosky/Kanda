import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'ItemModel.dart';

class ItemDetailsScreen extends StatelessWidget {
  final ItemModel item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionContent(item.title,
                fontSize: 24, fontWeight: FontWeight.bold),
            const SizedBox(height: 16.0),
            _buildImagePreview(item.imagePath),
            const SizedBox(height: 16.0),
            _buildSectionContent(item.description ?? ''),
            const SizedBox(height: 16.0),
            _buildSectionContent(DateFormat('yyyy-MM-dd')
                .format(DateTime.fromMillisecondsSinceEpoch(item.date))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content,
      {double fontSize = 16, FontWeight fontWeight = FontWeight.normal}) {
    return Text(
      content,
      style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
    );
  }

  Widget _buildImagePreview(String? imagePath) {
    return SizedBox(
      width: double.infinity,
      height: 240.0,
      child:
          imagePath != null && (!kIsWeb && File(item.imagePath!).existsSync())
              ? Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                )
              : Center(
                  child: Text('No image available'),
                ),
    );
  }
}
