class PetModel {
  final int? id;
  final String name;
  final String type; // 'default' | 'user_upload'
  final String imagePath; // absolute path in documents dir
  final bool isActive;
  final String? createdAt;

  const PetModel({
    this.id,
    required this.name,
    required this.type,
    required this.imagePath,
    this.isActive = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type,
        'image_path': imagePath,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  factory PetModel.fromMap(Map<String, dynamic> map) => PetModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        type: map['type'] as String? ?? 'default',
        imagePath: map['image_path'] as String,
        isActive: (map['is_active'] as int? ?? 0) == 1,
        createdAt: map['created_at'] as String?,
      );
}
