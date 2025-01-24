class Character {
  final int id;
  final String name;
  final String color;
  final bool isMale;
  final String hair;
  final String hairColor;
  final String eye;
  final String eyeColor;
  final String shirt;
  final String pants;
  final DateTime createdAt;

  Character(
    this.id,
    this.name,
    this.color,
    this.isMale,
    this.hair,
    this.hairColor,
    this.eye,
    this.eyeColor,
    this.shirt,
    this.pants,
    this.createdAt,
  );

  factory Character.fromMap(Map<String, dynamic> map) {
    return Character(
      map['id'],
      map['name'],
      map['color'],
      map['is_male'] == 1,
      map['hair'],
      map['hair_color'],
      map['eye'],
      map['eye_color'],
      map['shirt'],
      map['pants'],
      DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'is_male': isMale ? 1 : 0,
      'hair': hair,
      'hair_color': hairColor,
      'eye': eye,
      'eye_color': eyeColor,
      'shirt': shirt,
      'pants': pants,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
