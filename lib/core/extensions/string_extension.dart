extension StringExtension on String {
  // Validation
  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  bool get isValidPassword => length >= 8;
  bool get isValidPhoneNumber => RegExp(r'^\+?[0-9]{10,15}$').hasMatch(this);

  // Formatting
  String get capitalizeFirst =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
  String get capitalize =>
      split(' ').map((word) => word.capitalizeFirst).join(' ');
  String get removeSpaces => replaceAll(' ', '');
  String get camelCase => toLowerCase()
      .split(' ')
      .indexed
      .map((e) => e.$1 == 0 ? e.$2 : e.$2.capitalizeFirst)
      .join('');

  // Truncating
  String truncate(int maxLength) =>
      length > maxLength ? '${substring(0, maxLength)}...' : this;

  // File extensions
  bool get isImageFile =>
      toLowerCase().endsWith('.jpg') ||
      toLowerCase().endsWith('.jpeg') ||
      toLowerCase().endsWith('.png') ||
      toLowerCase().endsWith('.gif');

  bool get isDocumentFile =>
      toLowerCase().endsWith('.pdf') ||
      toLowerCase().endsWith('.doc') ||
      toLowerCase().endsWith('.docx');
}
