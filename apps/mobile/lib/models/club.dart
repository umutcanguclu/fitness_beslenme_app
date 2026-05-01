class Club {
  final String id;
  final String name;
  final String? city;
  final String? league;
  final int? foundedYear;
  final String? logoUrl;

  const Club({
    required this.id,
    required this.name,
    this.city,
    this.league,
    this.foundedYear,
    this.logoUrl,
  });

  factory Club.fromJson(Map<String, dynamic> json) => Club(
        id: json['id'] as String,
        name: json['name'] as String,
        city: json['city'] as String?,
        league: json['league'] as String?,
        foundedYear: json['foundedYear'] as int?,
        logoUrl: json['logoUrl'] as String?,
      );
}

class Facility {
  final String id;
  final String type; // 'football_pitch_grass' | 'gym' | etc.
  final String name;
  final String? notes;

  const Facility({required this.id, required this.type, required this.name, this.notes});

  factory Facility.fromJson(Map<String, dynamic> json) => Facility(
        id: json['id'] as String,
        type: json['type'] as String,
        name: json['name'] as String,
        notes: json['notes'] as String?,
      );
}

class Equipment {
  final String id;
  final String item;
  final int quantity;
  final String? notes;

  const Equipment({required this.id, required this.item, required this.quantity, this.notes});

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
        id: json['id'] as String,
        item: json['item'] as String,
        quantity: (json['quantity'] as num).toInt(),
        notes: json['notes'] as String?,
      );
}
