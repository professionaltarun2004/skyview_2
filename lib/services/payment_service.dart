import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:skyview_2/utils/error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skyview_2/models/payment.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get supported currencies and their rates
  Stream<List<Currency>> getSupportedCurrencies() {
    return _firestore
        .collection('currencies')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Currency.fromJson(doc.data()))
            .toList());
  }

  // Get payment methods for a specific country
  Stream<List<PaymentMethod>> getPaymentMethods(String countryCode) {
    return _firestore
        .collection('payment_methods')
        .where('countryCode', isEqualTo: countryCode)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentMethod.fromJson(doc.data()))
            .toList());
  }

  // Process payment
  Future<PaymentResult> processPayment({
    required String flightId,
    required double amount,
    required String currency,
    required String paymentMethodId,
    required Map<String, dynamic> paymentDetails,
  }) async {
    try {
      // Create payment record
      final paymentRef = await _firestore.collection('payments').add({
        'flightId': flightId,
        'amount': amount,
        'currency': currency,
        'paymentMethodId': paymentMethodId,
        'paymentDetails': paymentDetails,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // TODO: Integrate with actual payment gateway (Stripe, PayPal, etc.)
      // For now, simulate successful payment
      await Future.delayed(const Duration(seconds: 2));

      // Update payment status
      await paymentRef.update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      return PaymentResult(
        success: true,
        paymentId: paymentRef.id,
        message: 'Payment successful',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Payment failed: ${e.toString()}',
      );
    }
  }
  
  // Get saved payment methods
  Future<List<PaymentMethod>> getSavedPaymentMethods() async {
    try {
      if (_auth.currentUser == null) {
        return [];
      }
      
      final userId = _auth.currentUser!.uid;
      
      final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('paymentMethods')
        .get();
      
      return snapshot.docs.map((doc) => PaymentMethod.fromJson(doc.data())).toList();
    } catch (e) {
      ErrorHandler.logError('PaymentService', 'Error fetching payment methods: $e', null);
      return [];
    }
  }
  
  // Add a new payment method
  Future<Map<String, dynamic>> addPaymentMethod({
    required String type,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cardholderName,
    required String cvv,
    bool isDefault = false,
  }) async {
    try {
      if (_auth.currentUser == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }
      
      // Validate card number (basic check)
      if (cardNumber.replaceAll(' ', '').length < 12) {
        return {
          'success': false,
          'message': 'Invalid card number',
        };
      }
      
      // Validate expiry date
      final now = DateTime.now();
      if (expiryYear < now.year || 
          (expiryYear == now.year && expiryMonth < now.month)) {
        return {
          'success': false,
          'message': 'Card has expired',
        };
      }
      
      final userId = _auth.currentUser!.uid;
      
      // Get the last 4 digits
      final last4 = cardNumber.replaceAll(' ', '').substring(cardNumber.length - 4);
      
      // If this is the default card, update all other cards to not be default
      if (isDefault) {
        final batch = _firestore.batch();
        
        final existingMethods = await _firestore
          .collection('users')
          .doc(userId)
          .collection('paymentMethods')
          .where('isDefault', isEqualTo: true)
          .get();
        
        for (var doc in existingMethods.docs) {
          batch.update(doc.reference, {'isDefault': false});
        }
        
        await batch.commit();
      }
      
      // Add new payment method
      final methodRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('paymentMethods')
        .doc();
      
      final paymentMethod = PaymentMethod(
        id: methodRef.id,
        type: type,
        name: type,
        countryCode: 'IN', // Default to India
        supportedCurrencies: ['INR', 'USD'],
        last4: last4,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cardholderName: cardholderName,
        isDefault: isDefault,
      );
      
      await methodRef.set(paymentMethod.toJson());
      
      return {
        'success': true,
        'message': 'Payment method added successfully',
        'id': methodRef.id,
      };
    } catch (e) {
      ErrorHandler.logError('PaymentService', 'Error adding payment method: $e', null);
      return {
        'success': false,
        'message': 'Failed to add payment method',
      };
    }
  }
  
  // Delete a payment method
  Future<bool> deletePaymentMethod(String paymentMethodId) async {
    try {
      if (_auth.currentUser == null) {
        return false;
      }
      
      final userId = _auth.currentUser!.uid;
      
      await _firestore
        .collection('users')
        .doc(userId)
        .collection('paymentMethods')
        .doc(paymentMethodId)
        .delete();
      
      return true;
    } catch (e) {
      ErrorHandler.logError('PaymentService', 'Error deleting payment method: $e', null);
      return false;
    }
  }
  
  // Set a payment method as default
  Future<bool> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      if (_auth.currentUser == null) {
        return false;
      }
      
      final userId = _auth.currentUser!.uid;
      final batch = _firestore.batch();
      
      // First, set all methods to non-default
      final existingMethods = await _firestore
        .collection('users')
        .doc(userId)
        .collection('paymentMethods')
        .get();
      
      for (var doc in existingMethods.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      
      // Then set the specified method as default
      batch.update(
        _firestore
          .collection('users')
          .doc(userId)
          .collection('paymentMethods')
          .doc(paymentMethodId),
        {'isDefault': true}
      );
      
      await batch.commit();
      return true;
    } catch (e) {
      ErrorHandler.logError('PaymentService', 'Error setting default payment method: $e', null);
      return false;
    }
  }
} 