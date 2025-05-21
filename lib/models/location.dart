class Location {
  final String code;
  final String name;
  final String city;
  final String country;
  final String airportName;
  final bool isPopular;
  final int popularity;
  final List<String> searchKeywords;
  final String? imageUrl;
  final double latitude;
  final double longitude;

  Location({
    required this.code,
    required this.name,
    required this.city,
    required this.country,
    required this.airportName,
    this.isPopular = false,
    this.popularity = 0,
    required this.searchKeywords,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      code: json['code'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      airportName: json['airportName'] as String,
      isPopular: json['isPopular'] as bool? ?? false,
      popularity: json['popularity'] as int? ?? 0,
      searchKeywords: List<String>.from(json['searchKeywords'] ?? []),
      imageUrl: json['imageUrl'] as String?,
      latitude: json['latitude'] as double? ?? 0.0,
      longitude: json['longitude'] as double? ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'city': city,
      'country': country,
      'airportName': airportName,
      'isPopular': isPopular,
      'popularity': popularity,
      'searchKeywords': searchKeywords,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get displayName => '$city, $country';
  String get fullName => '$airportName ($code)';
  String get shortName => '$city ($code)';

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
} 