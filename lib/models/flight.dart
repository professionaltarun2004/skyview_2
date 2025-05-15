class Flight {
  final String id;
  final String airline;
  final String flightNumber;
  final String departureCity;
  final String arrivalCity;
  final String departureAirport;
  final String arrivalAirport;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double price;
  final String? logo;
  final bool isNonStop;
  final int availableSeats;
  final List<String> amenities;
  final Duration duration;

  Flight({
    required this.id,
    required this.airline,
    required this.flightNumber,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    this.logo,
    required this.isNonStop,
    required this.availableSeats,
    required this.amenities,
    required this.duration,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      id: json['id'],
      airline: json['airline'],
      flightNumber: json['flightNumber'],
      departureCity: json['departureCity'],
      arrivalCity: json['arrivalCity'],
      departureAirport: json['departureAirport'],
      arrivalAirport: json['arrivalAirport'],
      departureTime: DateTime.parse(json['departureTime']),
      arrivalTime: DateTime.parse(json['arrivalTime']),
      price: json['price'].toDouble(),
      logo: json['logo'],
      isNonStop: json['isNonStop'],
      availableSeats: json['availableSeats'],
      amenities: List<String>.from(json['amenities']),
      duration: Duration(minutes: json['durationMinutes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'airline': airline,
      'flightNumber': flightNumber,
      'departureCity': departureCity,
      'arrivalCity': arrivalCity,
      'departureAirport': departureAirport,
      'arrivalAirport': arrivalAirport,
      'departureTime': departureTime.toIso8601String(),
      'arrivalTime': arrivalTime.toIso8601String(),
      'price': price,
      'logo': logo,
      'isNonStop': isNonStop,
      'availableSeats': availableSeats,
      'amenities': amenities,
      'durationMinutes': duration.inMinutes,
    };
  }
} 