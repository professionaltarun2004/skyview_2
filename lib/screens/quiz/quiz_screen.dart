import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _formKey = GlobalKey<FormState>();
  String _seatPref = 'Window';
  String _mealPref = 'Vegetarian';
  String _travelType = 'Leisure';
  bool _submitted = false;

  Future<void> _submitQuiz() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'quiz': {
        'seatPref': _seatPref,
        'mealPref': _mealPref,
        'travelType': _travelType,
      }
    }, SetOptions(merge: true));
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Travel Quiz')),
        body: const Center(child: Text('Thank you! Your preferences have been saved.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Travel Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('What is your seat preference?'),
              DropdownButton<String>(
                value: _seatPref,
                items: const [
                  DropdownMenuItem(value: 'Window', child: Text('Window')),
                  DropdownMenuItem(value: 'Aisle', child: Text('Aisle')),
                  DropdownMenuItem(value: 'Middle', child: Text('Middle')),
                ],
                onChanged: (v) => setState(() => _seatPref = v!),
              ),
              const SizedBox(height: 24),
              const Text('What is your meal preference?'),
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
              const SizedBox(height: 24),
              const Text('What is your primary travel type?'),
              DropdownButton<String>(
                value: _travelType,
                items: const [
                  DropdownMenuItem(value: 'Leisure', child: Text('Leisure')),
                  DropdownMenuItem(value: 'Business', child: Text('Business')),
                  DropdownMenuItem(value: 'Family', child: Text('Family')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _travelType = v!),
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _submitQuiz,
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 