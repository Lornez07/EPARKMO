class CarModel {
  final String id;
  final String plateNumber;
  final String model;
  final String color;

  const CarModel({
    required this.id,
    required this.plateNumber,
    required this.model,
    required this.color,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'plateNumber': plateNumber,
        'model': model,
        'color': color,
      };

  factory CarModel.fromMap(Map<String, dynamic> map) => CarModel(
        id: map['id'] ?? '',
        plateNumber: map['plateNumber'] ?? '',
        model: map['model'] ?? '',
        color: map['color'] ?? '',
      );

  CarModel copyWith({
    String? id,
    String? plateNumber,
    String? model,
    String? color,
  }) {
    return CarModel(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      model: model ?? this.model,
      color: color ?? this.color,
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'guest' | 'admin'
  final int failedReservations;
  final String? lastFailedDate; // Format: 'YYYY-MM-DD'
  final List<CarModel> cars;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.failedReservations = 0,
    this.lastFailedDate,
    this.cars = const [],
  });

  bool get isAdmin => role == 'admin';

  bool hasReachedDailyLimit() {
    if (failedReservations >= 3 && lastFailedDate != null) {
      final today = DateTime.now().toIso8601String().split('T')[0];
      return lastFailedDate == today;
    }
    return false;
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    int? failedReservations,
    String? lastFailedDate,
    List<CarModel>? cars,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      failedReservations: failedReservations ?? this.failedReservations,
      lastFailedDate: lastFailedDate ?? this.lastFailedDate,
      cars: cars ?? this.cars,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'name': name,
        'role': role,
        'failedReservations': failedReservations,
        'lastFailedDate': lastFailedDate,
        'cars': cars.map((c) => c.toMap()).toList(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) {
    var carsList = <CarModel>[];
    if (map['cars'] != null && map['cars'] is List) {
      carsList = (map['cars'] as List)
          .map((c) => CarModel.fromMap(Map<String, dynamic>.from(c)))
          .toList();
    }

    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'guest',
      failedReservations: map['failedReservations'] ?? 0,
      lastFailedDate: map['lastFailedDate'],
      cars: carsList,
    );
  }
}
