import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skyview_2/widgets/snap_card.dart';
import 'package:skyview_2/screens/flights/flight_results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _departDateController = TextEditingController();
  final TextEditingController _returnDateController = TextEditingController();
  final TextEditingController _passengersController = TextEditingController(text: '1');
  
  bool _isRoundTrip = true;
  String _travelClass = 'Economy';
  
  @override
  void initState() {
    super.initState();
    // Set default dates
    final now = DateTime.now();
    final departDate = now.add(const Duration(days: 7));
    final returnDate = now.add(const Duration(days: 14));
    
    _departDateController.text = DateFormat('MMM dd, yyyy').format(departDate);
    _returnDateController.text = DateFormat('MMM dd, yyyy').format(returnDate);
  }
  
  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _departDateController.dispose();
    _returnDateController.dispose();
    _passengersController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  void _searchFlights() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FlightResultsScreen(
            from: _fromController.text,
            to: _toController.text,
            departDate: _departDateController.text,
            returnDate: _isRoundTrip ? _returnDateController.text : null,
            passengers: int.parse(_passengersController.text),
            travelClass: _travelClass,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Flights'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip type selector
              SnapCard(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isRoundTrip = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isRoundTrip
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Round Trip',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isRoundTrip ? Colors.white : null,
                              fontWeight: _isRoundTrip ? FontWeight.bold : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isRoundTrip = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isRoundTrip
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'One Way',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isRoundTrip ? Colors.white : null,
                              fontWeight: !_isRoundTrip ? FontWeight.bold : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // From and To Fields
              SnapCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _fromController,
                      decoration: const InputDecoration(
                        labelText: 'From',
                        prefixIcon: Icon(Icons.flight_takeoff),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter origin city';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: Divider()),
                        IconButton(
                          icon: const Icon(Icons.swap_vert),
                          onPressed: () {
                            final temp = _fromController.text;
                            setState(() {
                              _fromController.text = _toController.text;
                              _toController.text = temp;
                            });
                          },
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _toController,
                      decoration: const InputDecoration(
                        labelText: 'To',
                        prefixIcon: Icon(Icons.flight_land),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter destination city';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Date Selection
              SnapCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _departDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Departure Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context, _departDateController),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select departure date';
                        }
                        return null;
                      },
                    ),
                    if (_isRoundTrip) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _returnDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Return Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () => _selectDate(context, _returnDateController),
                        validator: (value) {
                          if (_isRoundTrip && (value == null || value.isEmpty)) {
                            return 'Please select return date';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Passengers and Class
              SnapCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _passengersController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Passengers',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter number of passengers';
                        }
                        if (int.tryParse(value) == null || int.parse(value) < 1) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _travelClass,
                      decoration: const InputDecoration(
                        labelText: 'Travel Class',
                        prefixIcon: Icon(Icons.airline_seat_recline_normal),
                      ),
                      items: ['Economy', 'Premium Economy', 'Business', 'First']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _travelClass = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Search Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _searchFlights,
                  icon: const Icon(Icons.search),
                  label: const Text('Search Flights'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 