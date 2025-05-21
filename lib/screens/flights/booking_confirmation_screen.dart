import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skyview_2/models/flight.dart';
import 'package:skyview_2/widgets/snap_card.dart';
import 'package:lottie/lottie.dart';
import 'package:skyview_2/widgets/custom_button.dart';
import 'package:skyview_2/utils/constants.dart';
import 'package:skyview_2/utils/extensions.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:skyview_2/services/booking_service.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Flight flight;
  final int passengers;
  final String travelClass;
  final double totalPrice;

  const BookingConfirmationScreen({
    super.key,
    required this.flight,
    required this.passengers,
    required this.travelClass,
    required this.totalPrice,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  Razorpay? _razorpay;
  bool _isPaying = false;
  bool _paymentSuccess = false;
  String? _paymentId;
  String? _paymentMethod;
  String? _errorMessage;
  bool _showQR = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isPaying = false;
      _paymentSuccess = true;
      _paymentId = response.paymentId;
      _paymentMethod = 'Razorpay';
    });
    await _createBooking();
    _showFeedbackDialog();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isPaying = false;
      _errorMessage = 'Payment failed. Please try again.';
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _isPaying = false;
      _errorMessage = 'External wallet selected.';
    });
  }

  void _startRazorpayPayment() {
    setState(() {
      _isPaying = true;
      _errorMessage = null;
    });
    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Replace with your Razorpay key
      'amount': (widget.totalPrice * 100).toInt(),
      'name': 'SkyView Flights',
      'description': 'Flight Booking',
      'prefill': {'contact': '', 'email': ''},
      'currency': 'INR',
    };
    try {
      _razorpay!.open(options);
    } catch (e) {
      setState(() {
        _isPaying = false;
        _errorMessage = 'Error starting payment: $e';
      });
    }
  }

  void _showGooglePayQR() {
    setState(() {
      _showQR = true;
      _errorMessage = null;
    });
  }

  Future<void> _onGooglePayPaid() async {
    setState(() {
      _isPaying = true;
      _errorMessage = null;
    });
    // Simulate payment success for demo
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isPaying = false;
      _paymentSuccess = true;
      _paymentId = 'gpay_${DateTime.now().millisecondsSinceEpoch}';
      _paymentMethod = 'Google Pay';
    });
    await _createBooking();
    _showFeedbackDialog();
  }

  Future<void> _createBooking() async {
    await BookingService().createBooking(
      flight: widget.flight,
      passengers: widget.passengers,
      travelClass: widget.travelClass,
      totalPrice: widget.totalPrice,
      passengerInfo: {}, // TODO: Pass real passenger info
      paymentId: _paymentId,
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thank you!'),
        content: const Text('Would you like to give feedback or take a quick travel quiz to improve your recommendations?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No, thanks'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to quiz screen
            },
            child: const Text('Take Quiz'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Show feedback form
            },
            child: const Text('Give Feedback'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Generate a random booking reference
    final bookingRef = 'SKY${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13)}';
    
    final formatter = NumberFormat.currency(
      symbol: '₹',
      locale: 'en_IN',
      decimalDigits: 0,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success animation
            SizedBox(
              height: 150,
              child: Lottie.asset(
                AppConstants.successAnimation,
                repeat: false,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Failed to load success animation: $error');
                  return const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green,
                  );
                },
              ),
            ),
            
            const Text(
              'Your booking is confirmed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Booking reference: $bookingRef',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Flight details
            SnapCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Flight Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(widget.flight.departureTime),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(widget.flight.departureCity),
                          Text(
                            widget.flight.departureTime.toFormattedDate(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      
                      const Expanded(
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.flight),
                              SizedBox(height: 4),
                              Text('Direct'),
                            ],
                          ),
                        ),
                      ),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(widget.flight.arrivalTime),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(widget.flight.arrivalCity),
                          Text(
                            widget.flight.arrivalTime.toFormattedDate(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const Divider(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Airline'),
                      Text('${widget.flight.airlineName} (${widget.flight.flightNumber})'),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Class'),
                      Text(widget.travelClass),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Passengers'),
                      Text('${widget.passengers}'),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Payment step
            if (!_paymentSuccess) ...[
              const Text('Choose Payment Method:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isPaying ? null : _startRazorpayPayment,
                    icon: const Icon(Icons.payment),
                    label: const Text('Razorpay'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isPaying ? null : _showGooglePayQR,
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Google Pay'),
                  ),
                ],
              ),
              if (_showQR) ...[
                const SizedBox(height: 16),
                const Text('Scan this QR with Google Pay to pay:'),
                Center(
                  child: QrImageView(
                    data: 'upi://pay?pa=your-upi-id@okicici&pn=SkyView&am=${widget.totalPrice}&cu=INR',
                    version: QrVersions.auto,
                    size: 180.0,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: ElevatedButton(
                    onPressed: _isPaying ? null : _onGooglePayPaid,
                    child: const Text('I have paid'),
                  ),
                ),
              ],
              if (_isPaying) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Payment successful! Your booking is confirmed.',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Passenger details
            SnapCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Passenger Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Primary Passenger',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const Text('Name:'),
                      Text(
                        'John Doe',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const Text('Email:'),
                      Text(
                        'john.doe@example.com',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  if (widget.passengers > 1) ...[
                    const Divider(height: 24),
                    
                    Text(
                      'Additional Passengers (${widget.passengers - 1})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: CustomButton(
                    text: 'Share',
                    icon: Icons.share,
                    type: ButtonType.secondary,
                    onPressed: () {
                      // TODO: Implement share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sharing booking details...'),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: CustomButton(
                    text: 'E-ticket',
                    icon: Icons.download,
                    type: ButtonType.primary,
                    onPressed: () {
                      // TODO: Implement download functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Downloading e-ticket...'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            CustomButton(
              text: 'Back to Home',
              icon: Icons.home,
              fullWidth: true,
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
} 