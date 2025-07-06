class Name {
  final String id;
  final String name;
  final String description;
  final String gender;
  final String religion;

  Name({
    required this.id,
    required this.name,
    required this.description,
    required this.gender,
    required this.religion,
  });

  factory Name.fromMap(Map<String, dynamic> map) {
    return Name(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      gender: map['gender'] as String,
      religion: map['religion'] as String,
    );
  }
}
