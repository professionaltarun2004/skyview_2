import 'package:flutter/material.dart';
import 'package:skyview_2/models/payment.dart';
import 'package:skyview_2/services/payment_service.dart';
import 'package:skyview_2/utils/error_handler.dart';
import 'package:skyview_2/widgets/loading_indicator.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String paymentId;
  final double amount;
  final String currency;

  const PaymentSuccessScreen({
    Key? key,
    required this.paymentId,
    required this.amount,
    required this.currency,
  }) : super(key: key);

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = true;
  Map<String, dynamic>? _paymentDetails;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  Future<void> _loadPaymentDetails() async {
    try {
      // TODO: Implement payment details fetching from Firestore
      // For now, use mock data
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _paymentDetails = {
          'status': 'completed',
          'completedAt': DateTime.now().toIso8601String(),
          'paymentMethod': {
            'type': 'credit_card',
            'last4': '4242',
          },
        };
        _isLoading = false;
      });
    } catch (e) {
      ErrorHandler.logError('PaymentSuccessScreen', 'Error loading payment details: $e', null);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your payment has been processed successfully.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Payment ID',
                        widget.paymentId,
                      ),
                      const Divider(),
                      _buildDetailRow(
                        'Amount',
                        '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
                      ),
                      const Divider(),
                      _buildDetailRow(
                        'Status',
                        _paymentDetails?['status'] ?? 'Unknown',
                      ),
                      const Divider(),
                      _buildDetailRow(
                        'Payment Method',
                        '${_paymentDetails?['paymentMethod']['type'] ?? 'Unknown'} ending in ${_paymentDetails?['paymentMethod']['last4'] ?? '****'}',
                      ),
                      const Divider(),
                      _buildDetailRow(
                        'Date',
                        _formatDate(_paymentDetails?['completedAt']),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to home screen
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  child: const Text('Return to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return 'Unknown';
    }
  }
} 