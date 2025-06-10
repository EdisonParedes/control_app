class VisitorQR {
  final String name;
  final String lastname;
  final String id;
  final String type;
  final String phone;

  VisitorQR({
    required this.name,
    required this.lastname,
    required this.id,
    required this.type,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'lastname': lastname,
        'id': id,
        'type': type,
        'phone': phone,
      };

  factory VisitorQR.fromJson(Map<String, dynamic> json) => VisitorQR(
        name: json['name'],
        lastname: json['lastname'],
        id: json['id'],
        type: json['type'],
        phone: json['phone'],
      );
}
