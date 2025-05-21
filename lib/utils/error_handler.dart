import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

enum ErrorSeverity { low, medium, high }

class ErrorHandler {
  // Log error to console and Crashlytics if available
  static void logError(String source, dynamic error, StackTrace? stackTrace) {
    // Always log to console
    debugPrint('ERROR in $source: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
    
    // Log to Crashlytics in non-debug mode
    if (!kDebugMode) {
      try {
        // Record error in Crashlytics
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: 'Error in $source',
        );
      } catch (e) {
        // Crashlytics may not be initialized
        debugPrint('Failed to log to Crashlytics: $e');
      }
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
  
  // Get user-friendly error message
  static String getUserFriendlyError(dynamic error) {
    if (error == null) {
      return 'An unexpected error occurred';
    }
    
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('network') || errorStr.contains('connection') || 
        errorStr.contains('socket') || errorStr.contains('timeout')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return 'Permission denied. Please check your app permissions.';
    } else if (errorStr.contains('not found') || errorStr.contains('404')) {
      return 'The requested resource was not found.';
    } else if (errorStr.contains('server') || errorStr.contains('500')) {
      return 'Server error. Please try again later.';
    } else if (errorStr.contains('authentication') || errorStr.contains('unauthorized') || 
              errorStr.contains('401') || errorStr.contains('login')) {
      return 'Authentication failed. Please log in again.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }
  
  // Parse Firebase authentication errors
  static String getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
} 