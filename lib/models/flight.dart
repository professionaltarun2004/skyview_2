import 'package:cloud_firestore/cloud_firestore.dart';

class Flight {
  final String id;
  final String airlineName;
  final String flightNumber;
  final String departureCity;
  final String arrivalCity;
  final String departureAirport;
  final String arrivalAirport;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double price;
  final int availableSeats;
  final List<String> travelClasses;
  final List<String> amenities;
  final String status;
  final String? gate;
  final String? terminal;
  final DateTime? lastUpdated;
  final String? logo;
  final bool isNonStop;

  Flight({
    required this.id,
    required this.airlineName,
    required this.flightNumber,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.availableSeats,
    required this.travelClasses,
    required this.amenities,
    required this.status,
    this.gate,
    this.terminal,
    this.lastUpdated,
    this.logo,
    this.isNonStop = true, required String airline, required Duration duration,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    // Handle both Firestore Timestamp and ISO string formats
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      }
      throw FormatException('Invalid date format: $value');
    }

    // Handle both camelCase and snake_case field names
    String getString(String camelCase, String snakeCase) {
      return json[camelCase] as String? ?? json[snakeCase] as String;
    }

    int getInt(String camelCase, String snakeCase) {
      return json[camelCase] as int? ?? json[snakeCase] as int;
    }

    List<String> getStringList(String camelCase, String snakeCase) {
      final camelList = json[camelCase] as List<dynamic>?;
      final snakeList = json[snakeCase] as List<dynamic>?;
      if (camelList != null) {
        return camelList.map((e) => e.toString()).toList();
      } else if (snakeList != null) {
        return snakeList.map((e) => e.toString()).toList();
      }
      return [];
    }

    return Flight(
      id: getString('id', 'flight_id'),
      airlineName: getString('airlineName', 'airline_name'),
      flightNumber: getString('flightNumber', 'flight_number'),
      departureCity: getString('departureCity', 'departure_city'),
      arrivalCity: getString('arrivalCity', 'arrival_city'),
      departureAirport: getString('departureAirport', 'departure_airport'),
      arrivalAirport: getString('arrivalAirport', 'arrival_airport'),
      departureTime: parseDateTime(json['departureTime'] ?? json['departure_time']),
      arrivalTime: parseDateTime(json['arrivalTime'] ?? json['arrival_time']),
      price: (json['price'] as num).toDouble(),
      availableSeats: getInt('availableSeats', 'available_seats'),
      travelClasses: getStringList('travelClasses', 'travel_classes'),
      amenities: getStringList('amenities', 'amenities'),
      status: json['status'] as String? ?? 'Scheduled',
      gate: json['gate'] as String?,
      terminal: json['terminal'] as String?,
      lastUpdated: json['lastUpdated'] != null || json['last_updated'] != null
          ? parseDateTime(json['lastUpdated'] ?? json['last_updated'])
          : null,
      logo: json['logo'] as String?,
      isNonStop: json['isNonStop'] as bool? ?? json['is_non_stop'] as bool? ?? true,
      airline: json['airline'] as String? ?? getString('airlineName', 'airline_name'),
      duration: (json['arrivalTime'] != null || json['arrival_time'] != null) &&
                (json['departureTime'] != null || json['departure_time'] != null)
          ? (parseDateTime(json['arrivalTime'] ?? json['arrival_time'])
              .difference(parseDateTime(json['departureTime'] ?? json['departure_time'])))
          : Duration.zero,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'airlineName': airlineName,
      'flightNumber': flightNumber,
      'departureCity': departureCity,
      'arrivalCity': arrivalCity,
      'departureAirport': departureAirport,
      'arrivalAirport': arrivalAirport,
      'departureTime': Timestamp.fromDate(departureTime),
      'arrivalTime': Timestamp.fromDate(arrivalTime),
      'price': price,
      'availableSeats': availableSeats,
      'travelClasses': travelClasses,
      'amenities': amenities,
      'status': status,
      'gate': gate,
      'terminal': terminal,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
      'logo': logo,
      'isNonStop': isNonStop,
    };
  }

  Duration get duration => arrivalTime.difference(departureTime);
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String get formattedDepartureTime => 
      '${departureTime.hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')}';
  
  String get formattedArrivalTime => 
      '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}';

  String get formattedDepartureDate => 
      '${departureTime.day}/${departureTime.month}/${departureTime.year}';
  
  String get formattedArrivalDate => 
      '${arrivalTime.day}/${arrivalTime.month}/${arrivalTime.year}';

  bool get isAvailable => availableSeats > 0 && status == 'Scheduled';
  bool get isDelayed => status == 'Delayed';
  bool get isCancelled => status == 'Cancelled';

  @override
  String toString() => '$airlineName $flightNumber: $departureCity → $arrivalCity';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Flight &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
} 