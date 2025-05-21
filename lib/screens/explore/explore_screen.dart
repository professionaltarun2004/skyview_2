import 'package:flutter/material.dart';
import 'package:skyview_2/widgets/snap_card.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final LatLng _initialPosition = LatLng(20.5937, 78.9629); // Center of India
  MapController? _mapController;
  
  final List<Map<String, dynamic>> _popularDestinations = [
    {
      'name': 'Goa',
      'image': 'assets/images/goa.jpg',
      'description': 'Beaches, nightlife, and relaxation',
      'position': LatLng(15.2993, 74.1240),
    },
    {
      'name': 'Kerala',
      'image': 'assets/images/kerala.jpg',
      'description': 'Backwaters, hills, and culture',
      'position': LatLng(10.1632, 76.6413),
    },
    {
      'name': 'Rajasthan',
      'image': 'assets/images/rajasthan.jpg',
      'description': 'Forts, palaces, and desert adventures',
      'position': LatLng(27.0238, 74.2179),
    },
    {
      'name': 'Shimla',
      'image': 'assets/images/shimla.jpg',
      'description': 'Hill station with scenic views',
      'position': LatLng(31.1048, 77.1734),
    },
  ];
  
  final List<Map<String, dynamic>> _deals = [
    {
      'title': 'Weekend Getaway',
      'destination': 'Mumbai to Goa',
      'discount': '15% OFF',
      'validTill': 'Valid till 30 Jun',
    },
    {
      'title': 'Summer Special',
      'destination': 'Delhi to Shimla',
      'discount': '₹1,200 OFF',
      'validTill': 'Valid till 15 Jul',
    },
    {
      'title': 'Monsoon Offer',
      'destination': 'Bangalore to Kerala',
      'discount': '20% OFF',
      'validTill': 'Valid till 31 Aug',
    },
  ];
  
  bool _isMapLoaded = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map for exploration
            _buildMap(),
            
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Popular Destinations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Popular destinations horizontal list
            SizedBox(
              height: 180,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _popularDestinations.length,
                itemBuilder: (context, index) {
                  final destination = _popularDestinations[index];
                  return _buildDestinationCard(destination);
                },
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Special Deals',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Special deals
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _deals.length,
              itemBuilder: (context, index) {
                final deal = _deals[index];
                return _buildDealCard(deal);
              },
            ),
            
            // Travel tips
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Travel Tips',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: SnapCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monsoon Travel Essentials',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Planning a trip during monsoon? Don\'t forget these essentials: '
                      'waterproof bags, umbrella, quick-dry clothes, water-resistant footwear, '
                      'and a first-aid kit including anti-fungal cream.',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        // TODO: Navigate to full article
                      },
                      child: const Text('Read More'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_mapController != null) {
            _mapController!.move(_initialPosition, 5);
          }
        },
        mini: true,
        child: const Icon(Icons.my_location),
      ),
    );
  }
  
  Widget _buildMap() {
    if (!_isMapLoaded) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _isMapLoaded = true;
            _mapController = MapController();
          });
        },
        child: Container(
          height: 200,
          color: Colors.grey[300],
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 48),
                SizedBox(height: 8),
                Text("Tap to load map"),
              ],
            ),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 200,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: _initialPosition,
          zoom: 5,
          interactiveFlags: InteractiveFlag.all,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.skyview_2',
          ),
          MarkerLayer(
            markers: _popularDestinations.map((destination) {
              return Marker(
                width: 40,
                height: 40,
                point: destination['position'],
                child: const Icon(Icons.location_on, color: Colors.red, size: 32),
              );
            }).toList().cast<Marker>(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDestinationCard(Map<String, dynamic> destination) {
    return GestureDetector(
      onTap: () {
        if (_mapController != null) {
          _mapController!.move(destination['position'], 10);
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        child: SnapCard(
          borderRadius: 12,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Image.asset(
                      destination['image'],
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.landscape, size: 40),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        destination['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  destination['description'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDealCard(Map<String, dynamic> deal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SnapCard(
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(deal['destination']),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  deal['discount'],
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deal['validTill'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 