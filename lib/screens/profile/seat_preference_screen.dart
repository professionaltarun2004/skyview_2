import 'package:flutter/material.dart';

class SeatPreferenceScreen extends StatefulWidget {
  const SeatPreferenceScreen({super.key});

  @override
  State<SeatPreferenceScreen> createState() => _SeatPreferenceScreenState();
}

class _SeatPreferenceScreenState extends State<SeatPreferenceScreen> {
  String _seatPref = 'Window';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seat Preference')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _seatPref,
              items: const [
                DropdownMenuItem(value: 'Window', child: Text('Window')),
                DropdownMenuItem(value: 'Aisle', child: Text('Aisle')),
                DropdownMenuItem(value: 'Middle', child: Text('Middle')),
              ],
              onChanged: (v) => setState(() => _seatPref = v!),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
} 