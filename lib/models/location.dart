class Wilaya {
  final int id;
  final String name;
  final String? arName;
  final String? code;

  Wilaya({
    required this.id,
    required this.name,
    this.arName,
    this.code,
  });

  factory Wilaya.fromJson(Map<String, dynamic> json) {
    return Wilaya(
      id: json['id'],
      name: json['name'],
      arName: json['ar_name'],
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ar_name': arName,
      'code': code,
    };
  }

  @override
  String toString() => name;
}

class Commune {
  final int id;
  final int wilayaId;
  final String name;
  final String? arName;
  final String? postCode;

  Commune({
    required this.id,
    required this.wilayaId,
    required this.name,
    this.arName,
    this.postCode,
  });

  factory Commune.fromJson(Map<String, dynamic> json) {
    return Commune(
      id: json['id'],
      wilayaId: json['wilaya_id'],
      name: json['name'],
      arName: json['ar_name'],
      postCode: json['post_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wilaya_id': wilayaId,
      'name': name,
      'ar_name': arName,
      'post_code': postCode,
    };
  }

  @override
  String toString() => name;
}
