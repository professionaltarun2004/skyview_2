import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skyview_2/models/flight.dart';
import 'package:skyview_2/utils/error_handler.dart';

enum BookingStatus {
  confirmed,
  cancelled,
  completed,
  pending,
}

class Booking {
  final String id;
  final String referenceNumber;
  final Flight flight;
  final int passengers;
  final String travelClass;
  final double totalPrice;
  final DateTime bookingDate;
  final BookingStatus status;
  final Map<String, dynamic>? cancellationDetails;
  final Map<String, dynamic> passengerInfo;
  final String? paymentId;

  const Booking({
    required this.id,
    required this.referenceNumber,
    required this.flight,
    required this.passengers,
    required this.travelClass,
    required this.totalPrice,
    required this.bookingDate,
    required this.status,
    this.cancellationDetails,
    required this.passengerInfo,
    this.paymentId,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Booking(
      id: doc.id,
      referenceNumber: data['referenceNumber'],
      flight: Flight.fromJson(data['flight']),
      passengers: data['passengers'],
      travelClass: data['travelClass'],
      totalPrice: data['totalPrice'].toDouble(),
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      status: _statusFromString(data['status']),
      cancellationDetails: data['cancellationDetails'],
      passengerInfo: data['passengerInfo'],
      paymentId: data['paymentId'],
    );
  }
  
  static BookingStatus _statusFromString(String status) {
    switch (status) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      case 'pending':
        return BookingStatus.pending;
      default:
        return BookingStatus.confirmed;
    }
  }
  
  static String _statusToString(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.pending:
        return 'pending';
    }
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'referenceNumber': referenceNumber,
      'flight': flight.toJson(),
      'passengers': passengers,
      'travelClass': travelClass,
      'totalPrice': totalPrice,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'status': _statusToString(status),
      'cancellationDetails': cancellationDetails,
      'passengerInfo': passengerInfo,
      'paymentId': paymentId,
    };
  }
  
  // Calculate cancellation fee based on days left
  double calculateCancellationFee() {
    final now = DateTime.now();
    final flightDate = flight.departureTime;
    final difference = flightDate.difference(now).inDays;
    
    // Cancellation policy
    if (difference < 1) {
      // Less than 24 hours - 100% fee
      return totalPrice;
    } else if (difference < 3) {
      // 1-3 days - 75% fee
      return totalPrice * 0.75;
    } else if (difference < 7) {
      // 3-7 days - 50% fee
      return totalPrice * 0.5;
    } else if (difference < 15) {
      // 7-15 days - 25% fee
      return totalPrice * 0.25;
    } else {
      // More than 15 days - 10% fee
      return totalPrice * 0.1;
    }
  }
  
  // Get refund amount
  double getRefundAmount() {
    if (status != BookingStatus.cancelled) {
      return 0;
    }
    
    final cancellationFee = calculateCancellationFee();
    return totalPrice - cancellationFee;
  }
  
  // Check if booking can be cancelled
  bool get canCancel {
    final now = DateTime.now();
    final flightDate = flight.departureTime;
    
    // Cannot cancel if flight has already departed
    if (now.isAfter(flightDate)) {
      return false;
    }
    
    // Cannot cancel if already cancelled
    if (status == BookingStatus.cancelled) {
      return false;
    }
    
    // Cannot cancel if flight is completed
    if (status == BookingStatus.completed) {
      return false;
    }
    
    return true;
  }
}

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required Flight flight,
    required int passengers,
    required String travelClass,
    required double totalPrice,
    required Map<String, dynamic> passengerInfo,
    String? paymentId,
  }) async {
    try {
      if (_auth.currentUser == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }
      
      final userId = _auth.currentUser!.uid;
      
      // Generate booking reference
      final referenceNumber = 'SKY${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13)}';
      
      // Create booking in Firestore
      final bookingRef = _firestore.collection('bookings').doc();
      
      await bookingRef.set({
        'userId': userId,
        'referenceNumber': referenceNumber,
        'flight': flight.toJson(),
        'passengers': passengers,
        'travelClass': travelClass,
        'totalPrice': totalPrice,
        'bookingDate': FieldValue.serverTimestamp(),
        'status': 'confirmed',
        'passengerInfo': passengerInfo,
        'paymentId': paymentId,
      });
      
      return {
        'success': true,
        'bookingId': bookingRef.id,
        'referenceNumber': referenceNumber,
      };
    } catch (e) {
      ErrorHandler.logError('BookingService', 'Error creating booking: $e', null);
      return {
        'success': false,
        'message': 'Failed to create booking: ${e.toString()}',
      };
    }
  }
  
  // Get all bookings for current user
  Future<List<Booking>> getBookings() async {
    try {
      if (_auth.currentUser == null) {
        return [];
      }
      
      final userId = _auth.currentUser!.uid;
      
      final snapshot = await _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('bookingDate', descending: true)
        .get();
      
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    } catch (e) {
      ErrorHandler.logError('BookingService', 'Error fetching bookings: $e', null);
      return [];
    }
  }
  
  // Get booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return Booking.fromFirestore(doc);
    } catch (e) {
      ErrorHandler.logError('BookingService', 'Error fetching booking: $e', null);
      return null;
    }
  }
  
  // Cancel a booking
  Future<Map<String, dynamic>> cancelBooking(String bookingId, String reason) async {
    try {
      if (_auth.currentUser == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }
      
      final booking = await getBookingById(bookingId);
      
      if (booking == null) {
        return {
          'success': false,
          'message': 'Booking not found',
        };
      }
      
      if (!booking.canCancel) {
        return {
          'success': false,
          'message': 'This booking cannot be cancelled',
        };
      }
      
      final cancellationFee = booking.calculateCancellationFee();
      final refundAmount = booking.totalPrice - cancellationFee;
      
      // Update booking status in Firestore
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancellationDetails': {
          'date': FieldValue.serverTimestamp(),
          'reason': reason,
          'cancellationFee': cancellationFee,
          'refundAmount': refundAmount,
        },
      });
      
      // Process refund if payment was made
      if (booking.paymentId != null) {
        // In a real app, this would call payment gateway for refund
        await _firestore.collection('refunds').add({
          'bookingId': bookingId,
          'paymentId': booking.paymentId,
          'amount': refundAmount,
          'status': 'processed',
          'date': FieldValue.serverTimestamp(),
        });
      }
      
      return {
        'success': true,
        'message': 'Booking cancelled successfully',
        'refundAmount': refundAmount,
      };
    } catch (e) {
      ErrorHandler.logError('BookingService', 'Error cancelling booking: $e', null);
      return {
        'success': false,
        'message': 'Failed to cancel booking',
      };
    }
  }
} 