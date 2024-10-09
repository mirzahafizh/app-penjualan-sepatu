class ShoeType {
  final String id;
  final String name;

  ShoeType({required this.id, required this.name});

  factory ShoeType.fromJson(Map<String, dynamic> json) {
    return ShoeType(
      id: json['id'],
      name: json['name'],
    );
  }
}
