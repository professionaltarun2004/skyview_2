import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skyview_2/providers/auth_provider.dart';
import 'package:skyview_2/providers/theme_provider.dart';
import 'package:skyview_2/widgets/snap_card.dart';
import 'package:skyview_2/services/booking_service.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings screen
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            SnapCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      size: 36,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.user?.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authProvider.user?.email ?? 'user@example.com',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/edit_profile');
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recent bookings
            const Text(
              'My Bookings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            FutureBuilder<List<Booking>>(
              future: BookingService().getBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No bookings found. Book your next flight!'),
                  );
                }
                final bookings = snapshot.data!;
                return SnapCard(
                  child: Column(
                    children: bookings.map((booking) {
                      final flight = booking.flight;
                      final date = DateFormat('dd MMM yyyy').format(flight.departureTime);
                      final status = booking.status.toString().split('.').last;
                      Color statusColor;
                      switch (booking.status) {
                        case BookingStatus.confirmed:
                          statusColor = Colors.green;
                          break;
                        case BookingStatus.completed:
                          statusColor = Colors.grey;
                          break;
                        case BookingStatus.cancelled:
                          statusColor = Colors.red;
                          break;
                        case BookingStatus.pending:
                        default:
                          statusColor = Colors.orange;
                      }
                      return Column(
                        children: [
                          _buildBookingItem(
                            context,
                            origin: flight.departureCity,
                            destination: flight.arrivalCity,
                            date: date,
                            status: status[0].toUpperCase() + status.substring(1),
                            statusColor: statusColor,
                          ),
                          const Divider(),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Travel preferences
            const Text(
              'Travel Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            SnapCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.airline_seat_recline_normal),
                    title: const Text('Seat Preference'),
                    subtitle: const Text('Window'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pushNamed('/seat_preference');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.fastfood),
                    title: const Text('Meal Preference'),
                    subtitle: const Text('Vegetarian'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pushNamed('/meal_preference');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.credit_card),
                    title: const Text('Saved Payment Methods'),
                    subtitle: const Text('2 cards saved'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pushNamed('/payment_methods');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.quiz),
                    title: const Text('Take Travel Quiz'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pushNamed('/quiz');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.feedback),
                    title: const Text('Give Feedback'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pushNamed('/feedback');
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App settings
            const Text(
              'App Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            SnapCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    secondary: Icon(
                      themeProvider.themeMode == ThemeMode.dark 
                          ? Icons.dark_mode 
                          : Icons.light_mode,
                    ),
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      themeProvider.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Notifications'),
                    secondary: const Icon(Icons.notifications),
                    value: true, // TODO: Connect to actual notification settings
                    onChanged: (value) {
                      // TODO: Update notification settings
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Sign out button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await authProvider.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBookingItem(
    BuildContext context, {
    required String origin,
    required String destination,
    required String date,
    required String status,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.flight,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$origin to $destination',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 