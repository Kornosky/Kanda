class ItemModel {
  String? id; // Make the ID nullable

  String title;
  int date;
  bool isSelected;
  String description;
  String? imagePath;

  ItemModel({
    this.id,
    required this.title,
    required this.date,
    required this.isSelected,
    required this.description,
    this.imagePath,
  });

  // Factory method to create an ItemModel with a generated ID
  factory ItemModel.generateId({
    required String title,
    required int date,
    required bool isSelected,
    required String description,
    String? imagePath,
  }) {
    return ItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: date,
      isSelected: isSelected,
      description: description,
      imagePath: imagePath,
    );
  }

  ItemModel copyWith({
    String? id,
    String? title,
    int? date,
    bool? isSelected,
    String? description,
    String? imagePath,
  }) {
    return ItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      isSelected: isSelected ?? this.isSelected,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'isSelected': isSelected ? 1 : 0,
      'description': description,
      'imagePath': imagePath,
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'],
      title: map['title'],
      date: map['date'],
      isSelected: map['isSelected'] == 1,
      description: map['description'],
      imagePath: map['imagePath'],
    );
  }
}
