import 'package:flutter/material.dart';
import 'package:skyview_2/models/payment.dart';
import 'package:skyview_2/services/payment_service.dart';
import 'package:skyview_2/utils/error_handler.dart';
import 'package:skyview_2/widgets/loading_indicator.dart';

class PaymentScreen extends StatefulWidget {
  final String flightId;
  final double amount;
  final String currency;

  const PaymentScreen({
    Key? key,
    required this.flightId,
    required this.amount,
    required this.currency,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final _formKey = GlobalKey<FormState>();
  
  List<PaymentMethod> _savedMethods = [];
  List<Currency> _currencies = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  
  // New payment method fields
  final _cardNumberController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  final _expiryMonthController = TextEditingController();
  final _expiryYearController = TextEditingController();
  final _cvvController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load saved payment methods
      _savedMethods = await _paymentService.getSavedPaymentMethods();
      
      // Load currencies
      _paymentService.getSupportedCurrencies().listen((currencies) {
        setState(() {
          _currencies = currencies;
          _isLoading = false;
        });
      });
    } catch (e) {
      ErrorHandler.logError('PaymentScreen', 'Error loading payment data: $e', null);
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _processPayment(PaymentMethod method) async {
    try {
      setState(() => _isProcessing = true);
      
      final result = await _paymentService.processPayment(
        flightId: widget.flightId,
        amount: widget.amount,
        currency: widget.currency,
        paymentMethodId: method.id,
        paymentDetails: {
          'type': method.type,
          'last4': method.last4,
        },
      );
      
      if (result.success) {
        // Navigate to success screen
        Navigator.pushReplacementNamed(
          context,
          '/payment-success',
          arguments: {
            'paymentId': result.paymentId,
            'amount': widget.amount,
            'currency': widget.currency,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Payment failed')),
        );
      }
    } catch (e) {
      ErrorHandler.logError('PaymentScreen', 'Error processing payment: $e', null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process payment')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }
  
  Future<void> _addNewPaymentMethod() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      setState(() => _isProcessing = true);
      
      final result = await _paymentService.addPaymentMethod(
        type: 'credit_card',
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        expiryMonth: int.parse(_expiryMonthController.text),
        expiryYear: int.parse(_expiryYearController.text),
        cardholderName: _cardholderNameController.text,
        cvv: _cvvController.text,
        isDefault: _savedMethods.isEmpty, // Make default if first card
      );
      
      if (result['success']) {
        await _loadData(); // Reload payment methods
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment method added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (e) {
      ErrorHandler.logError('PaymentScreen', 'Error adding payment method: $e', null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add payment method')),
      );
    } finally {
      setState(() => _isProcessing = false);
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
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount'),
                        Text(
                          '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Saved payment methods
            if (_savedMethods.isNotEmpty) ...[
              const Text(
                'Saved Payment Methods',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _savedMethods.length,
                itemBuilder: (context, index) {
                  final method = _savedMethods[index];
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
                      trailing: method.isDefault
                          ? const Chip(
                              label: Text('Default'),
                              backgroundColor: Colors.blue,
                              labelStyle: TextStyle(color: Colors.white),
                            )
                          : null,
                      onTap: () => _processPayment(method),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
            
            // Add new payment method
            const Text(
              'Add New Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _cardNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Card Number',
                      hintText: '1234 5678 9012 3456',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter card number';
                      }
                      if (value.replaceAll(' ', '').length < 12) {
                        return 'Invalid card number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cardholderNameController,
                    decoration: const InputDecoration(
                      labelText: 'Cardholder Name',
                      hintText: 'John Doe',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter cardholder name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expiryMonthController,
                          decoration: const InputDecoration(
                            labelText: 'Month',
                            hintText: 'MM',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final month = int.tryParse(value);
                            if (month == null || month < 1 || month > 12) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _expiryYearController,
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            hintText: 'YYYY',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final year = int.tryParse(value);
                            if (year == null || year < DateTime.now().year) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                            hintText: '123',
                          ),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (value.length < 3) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _addNewPaymentMethod,
                      child: _isProcessing
                          ? const CircularProgressIndicator()
                          : const Text('Add Payment Method'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardholderNameController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
} 