class ItemModel {
  String id; // Make the ID nullable
  String userId; // Add the userId field

  String title;
  int date;
  int dateCreated;
  bool isSelected;
  bool isPrivate;
  String description;
  String? imagePath;

  ItemModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    required this.dateCreated,
    required this.isSelected,
    required this.isPrivate,
    required this.description,
    this.imagePath,
  });

  // Factory method to create an ItemModel with a generated ID
  factory ItemModel.generateId({
    required String id,
    required String userId,
    required String title,
    required int date,
    required int dateCreated,
    required bool isSelected,
    required bool isPrivate,
    required String description,
    String? imagePath,
  }) {
    return ItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      date: date,
      dateCreated: dateCreated,
      isSelected: isSelected,
      isPrivate: isPrivate,
      description: description,
      imagePath: imagePath,
    );
  }

  ItemModel copyWith({
    String? id,
    String? userId,
    String? title,
    int? date,
    int? dateCreated,
    bool? isSelected,
    String? description,
    String? imagePath,
  }) {
    return ItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      date: date ?? this.date,
      dateCreated: dateCreated ?? this.dateCreated,
      isSelected: isSelected ?? this.isSelected,
      isPrivate: isPrivate,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId, // Add userId to the toMap method
      'title': title,
      'date': date,
      'dateCreated': dateCreated,
      'isSelected': isSelected ? 1 : 0,
      'description': description,
      'imagePath': imagePath,
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      date: map['date'],
      dateCreated: map['dateCreated'],
      isSelected: map['isSelected'] == 1,
      isPrivate: map['isPrivate'] == 1,
      description: map['description'],
      imagePath: map['imagePath'],
    );
  }
}
