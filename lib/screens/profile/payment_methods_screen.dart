import 'package:flutter/material.dart';
import 'package:skyview_2/models/payment.dart';
import 'package:skyview_2/services/payment_service.dart';
import 'package:skyview_2/utils/error_handler.dart';
import 'package:skyview_2/widgets/loading_indicator.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final PaymentService _paymentService = PaymentService();
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      setState(() => _isLoading = true);
      _paymentMethods = await _paymentService.getSavedPaymentMethods();
    } catch (e) {
      ErrorHandler.logError('PaymentMethodsScreen', 'Error loading payment methods: $e', null);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePaymentMethod(PaymentMethod method) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Payment Method'),
          content: Text('Are you sure you want to delete this ${method.type} card ending in ${method.last4}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await _paymentService.deletePaymentMethod(method.id);
        if (success) {
          await _loadPaymentMethods();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment method deleted')),
            );
          }
        }
      }
    } catch (e) {
      ErrorHandler.logError('PaymentMethodsScreen', 'Error deleting payment method: $e', null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete payment method')),
        );
      }
    }
  }

  Future<void> _setDefaultPaymentMethod(PaymentMethod method) async {
    try {
      final success = await _paymentService.setDefaultPaymentMethod(method.id);
      if (success) {
        await _loadPaymentMethods();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Default payment method updated')),
          );
        }
      }
    } catch (e) {
      ErrorHandler.logError('PaymentMethodsScreen', 'Error setting default payment method: $e', null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update default payment method')),
        );
      }
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
      appBar: AppBar(title: const Text('Payment Methods')),
      body: _paymentMethods.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No Payment Methods',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a payment method to make bookings faster.',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to add payment method screen
                      Navigator.pushNamed(context, '/add-payment-method');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Payment Method'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final method = _paymentMethods[index];
                return Card(
                  child: ListTile(
                    leading: Image.asset(
                      method.typeImage,
                      width: 40,
                      height: 40,
                    ),
                    title: Text(method.maskedNumber),
                    subtitle: Text(
                      'Expires ${method.expiryFormatted}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (method.isDefault)
                          const Chip(
                            label: Text('Default'),
                            backgroundColor: Colors.blue,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        else
                          TextButton(
                            onPressed: () => _setDefaultPaymentMethod(method),
                            child: const Text('Set as Default'),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deletePaymentMethod(method),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _paymentMethods.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                // Navigate to add payment method screen
                Navigator.pushNamed(context, '/add-payment-method');
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
} 