import 'package:flutter/material.dart';

enum ErrorSeverity { low, medium, high }

class ErrorHandler {
  static void logError(String source, dynamic error, StackTrace? stackTrace) {
    // In production, you'd send this to a service like Firebase Crashlytics
    debugPrint('Error in $source: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
  
  static void showErrorSnackBar(
    BuildContext context, 
    String message, 
    {ErrorSeverity severity = ErrorSeverity.medium}
  ) {
    Color backgroundColor;
    
    switch (severity) {
      case ErrorSeverity.low:
        backgroundColor = Colors.blue;
        break;
      case ErrorSeverity.medium:
        backgroundColor = Colors.orange;
        break;
      case ErrorSeverity.high:
        backgroundColor = Colors.red;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
} 