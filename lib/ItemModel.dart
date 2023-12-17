class ItemModel {
  final int id;
  final String title;
  final int date;
  final bool isSelected;
  final String? description;
  final String? imagePath;

  ItemModel({
    required this.id,
    required this.title,
    required this.date,
    required this.isSelected,
    this.description,
    this.imagePath,
  });

  ItemModel copyWith({
    int? id,
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
