import 'package:flutter/material.dart';

class MealPreferenceScreen extends StatefulWidget {
  const MealPreferenceScreen({super.key});

  @override
  State<MealPreferenceScreen> createState() => _MealPreferenceScreenState();
}

class _MealPreferenceScreenState extends State<MealPreferenceScreen> {
  String _mealPref = 'Vegetarian';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Preference')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _mealPref,
              items: const [
                DropdownMenuItem(value: 'Vegetarian', child: Text('Vegetarian')),
                DropdownMenuItem(value: 'Non-Vegetarian', child: Text('Non-Vegetarian')),
                DropdownMenuItem(value: 'Vegan', child: Text('Vegan')),
                DropdownMenuItem(value: 'Jain', child: Text('Jain')),
              ],
              onChanged: (v) => setState(() => _mealPref = v!),
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