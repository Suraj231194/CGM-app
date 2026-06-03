/// Reusable input validators for forms throughout the app.
/// Returns null if valid, or an error message string if invalid.
class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    final pattern = RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[\w\-\.]+$');
    if (!pattern.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  static String? glucoseValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Glucose value is required.';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number.';
    }
    if (parsed < 20 || parsed > 500) {
      return 'Value must be between 20 and 500 mg/dL.';
    }
    return null;
  }

  static String? sensorSerialNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Sensor serial number is required.';
    }
    if (value.trim().length < 5) {
      return 'Serial number is too short.';
    }
    return null;
  }

  static String? positiveInteger(String? value, [String fieldName = 'Value']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return '$fieldName must be a positive number.';
    }
    return null;
  }

  static String? quantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required.';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 1 || parsed > 10) {
      return 'Quantity must be between 1 and 10.';
    }
    return null;
  }

  static String? shippingAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Shipping address is required.';
    }
    if (value.trim().length < 10) {
      return 'Please enter a complete address.';
    }
    return null;
  }

  static String? threshold(
    String? value, {
    required int min,
    required int max,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Threshold is required.';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number.';
    }
    if (parsed < min || parsed > max) {
      return 'Must be between $min and $max mg/dL.';
    }
    return null;
  }
}
