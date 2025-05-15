import 'package:flutter/material.dart';
import 'package:skyview_2/models/flight.dart';
import 'package:skyview_2/widgets/snap_card.dart';
import 'package:intl/intl.dart';
import 'package:skyview_2/screens/flights/flight_details_screen.dart';

class FlightResultsScreen extends StatefulWidget {
  final String from;
  final String to;
  final String departDate;
  final String? returnDate;
  final int passengers;
  final String travelClass;
  
  const FlightResultsScreen({
    super.key,
    required this.from,
    required this.to,
    required this.departDate,
    this.returnDate,
    required this.passengers,
    required this.travelClass,
  });

  @override
  State<FlightResultsScreen> createState() => _FlightResultsScreenState();
}

class _FlightResultsScreenState extends State<FlightResultsScreen> {
  bool _isLoading = true;
  List<Flight> _flights = [];
  String _sortBy = 'price'; // price, duration, departure
  
  @override
  void initState() {
    super.initState();
    _loadFlights();
  }
  
  Future<void> _loadFlights() async {
    setState(() {
      _isLoading = true;
    });
    
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock data
    _flights = [
      Flight(
        id: '1',
        airline: 'Indigo Airlines',
        flightNumber: 'IG 2453',
        departureCity: widget.from,
        arrivalCity: widget.to,
        departureAirport: '${widget.from} International Airport',
        arrivalAirport: '${widget.to} International Airport',
        departureTime: DateTime.now().add(const Duration(days: 3, hours: 10)),
        arrivalTime: DateTime.now().add(const Duration(days: 3, hours: 12, minutes: 30)),
        price: 4525.0,
        logo: 'assets/images/indigo.png',
        isNonStop: true,
        availableSeats: 43,
        amenities: ['Meal', 'WiFi', 'Entertainment'],
        duration: const Duration(hours: 2, minutes: 30),
      ),
      Flight(
        id: '2',
        airline: 'Air India',
        flightNumber: 'AI 873',
        departureCity: widget.from,
        arrivalCity: widget.to,
        departureAirport: '${widget.from} International Airport',
        arrivalAirport: '${widget.to} International Airport',
        departureTime: DateTime.now().add(const Duration(days: 3, hours: 8)),
        arrivalTime: DateTime.now().add(const Duration(days: 3, hours: 10, minutes: 45)),
        price: 5199.0,
        logo: 'assets/images/airindia.png',
        isNonStop: true,
        availableSeats: 21,
        amenities: ['Meal', 'WiFi', 'Entertainment', 'Power Outlets'],
        duration: const Duration(hours: 2, minutes: 45),
      ),
      Flight(
        id: '3',
        airline: 'SpiceJet',
        flightNumber: 'SJ 4302',
        departureCity: widget.from,
        arrivalCity: widget.to,
        departureAirport: '${widget.from} International Airport',
        arrivalAirport: '${widget.to} International Airport',
        departureTime: DateTime.now().add(const Duration(days: 3, hours: 16)),
        arrivalTime: DateTime.now().add(const Duration(days: 3, hours: 18, minutes: 15)),
        price: 3999.0,
        logo: 'assets/images/spicejet.png',
        isNonStop: false,
        availableSeats: 12,
        amenities: ['Meal'],
        duration: const Duration(hours: 2, minutes: 15),
      ),
    ];
    
    _sortFlights();
    
    setState(() {
      _isLoading = false;
    });
  }
  
  void _sortFlights() {
    switch (_sortBy) {
      case 'price':
        _flights.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'duration':
        _flights.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case 'departure':
        _flights.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.from} to ${widget.to}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.returnDate != null 
                  ? '${widget.departDate} - ${widget.returnDate}'
                  : widget.departDate,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Sort options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('Sort by: '),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Price'),
                  selected: _sortBy == 'price',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _sortBy = 'price';
                        _sortFlights();
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Duration'),
                  selected: _sortBy == 'duration',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _sortBy = 'duration';
                        _sortFlights();
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Departure'),
                  selected: _sortBy == 'departure',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _sortBy = 'departure';
                        _sortFlights();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Flight list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _flights.length,
                    itemBuilder: (context, index) {
                      final flight = _flights[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildFlightCard(flight),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFlightCard(Flight flight) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      locale: 'en_IN',
      decimalDigits: 0,
    );
    
    return SnapCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FlightDetailsScreen(
              flight: flight,
              passengers: widget.passengers,
              travelClass: widget.travelClass,
            ),
          ),
        );
      },
      elevation: 2,
      child: Column(
        children: [
          // Airline info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[200],
                // Using placeholder icon as we don't have the actual logos
                child: const Icon(Icons.flight, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                flight.airline,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(flight.flightNumber),
              const Spacer(),
              Text(
                formatter.format(flight.price),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Flight times
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('HH:mm').format(flight.departureTime),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(flight.departureCity),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${flight.duration.inHours}h ${flight.duration.inMinutes % 60}m',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const Divider(
                          thickness: 1,
                          indent: 20,
                          endIndent: 20,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: flight.isNonStop
                              ? const Text('Non-stop')
                              : const Text('1 stop'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('HH:mm').format(flight.arrivalTime),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(flight.arrivalCity),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Amenities
          Row(
            children: [
              ...flight.amenities.take(3).map((amenity) => 
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(
                      amenity,
                      style: const TextStyle(fontSize: 12),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              if (flight.amenities.length > 3)
                Text('+${flight.amenities.length - 3} more'),
              const Spacer(),
              Text('${flight.availableSeats} seats left'),
            ],
          ),
        ],
      ),
    );
  }
} 