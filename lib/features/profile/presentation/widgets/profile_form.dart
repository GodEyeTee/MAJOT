import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';

class ProfileForm extends StatefulWidget {
  final Profile profile;
  final bool isUpdating;

  const ProfileForm({
    super.key,
    required this.profile,
    this.isUpdating = false,
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  DateTime? _selectedDate;
  bool _isFormValid = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.profile.displayName ?? '',
    );
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
    _selectedDate = widget.profile.dateOfBirth;

    // Initialize phone controller
    String phoneNumber = '';
    if (widget.profile.phoneNumber != null &&
        widget.profile.phoneNumber!.isNotEmpty) {
      phoneNumber = widget.profile.phoneNumber!;
      // Remove +66 if exists
      if (phoneNumber.startsWith('+66')) {
        phoneNumber = phoneNumber.substring(3);
      }
      // Remove leading 0 if exists
      if (phoneNumber.startsWith('0')) {
        phoneNumber = phoneNumber.substring(1);
      }
    }

    _phoneController = TextEditingController(text: phoneNumber);
    _phoneController = TextEditingController(text: phoneNumber);
    // Add listeners
    _displayNameController.addListener(_checkForChanges);
    _bioController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);

    // Initial validation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateForm();
    });
  }

  void _checkForChanges() {
    setState(() {
      _hasChanges = true;
    });
    _validateForm();
  }

  void _validateForm() {
    setState(() {
      final isValid = _formKey.currentState?.validate() ?? false;
      _isFormValid = isValid && _hasChanges;
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }

    // Remove all non-digit characters
    String digits = value.replaceAll(RegExp(r'\D'), '');

    // Remove country code if present
    if (digits.startsWith('66')) {
      digits = digits.substring(2);
    }

    // Remove leading 0 if present
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length != 9) {
      return 'Phone number must be 9 digits';
    }

    return null;
  }

  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '';

    String digits = phone.replaceAll(RegExp(r'\D'), '');

    // Remove country code if present
    if (digits.startsWith('66')) {
      digits = digits.substring(2);
    }

    // Remove leading 0 if present
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    return digits;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Title
              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Update your personal details',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Display Name Field
              _buildModernTextField(
                controller: _displayNameController,
                label: 'Display Name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone Number Field
              _buildModernPhoneField(),
              const SizedBox(height: 20),

              // Date of Birth Field
              _buildDateField(),
              const SizedBox(height: 20),

              // Bio Field
              _buildModernTextField(
                controller: _bioController,
                label: 'Bio',
                icon: Icons.info_outline,
                maxLines: 3,
                hint: 'Tell us about yourself',
              ),
              const SizedBox(height: 32),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      (_isFormValid && !widget.isUpdating)
                          ? _updateProfile
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child:
                      widget.isUpdating
                          ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Updating...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.update),
                              const SizedBox(width: 8),
                              Text(
                                'Update Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _isFormValid
                                          ? Colors.white
                                          : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        onChanged: (_) => _validateForm(),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildModernPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        validator: _validatePhoneNumber,
        onChanged: (value) {
          // Auto format: remove leading 0
          if (value.startsWith('0') && value.length > 1) {
            _phoneController.value = TextEditingValue(
              text: value.substring(1),
              selection: TextSelection.collapsed(offset: value.length - 1),
            );
          }
          _checkForChanges();
        },
        decoration: InputDecoration(
          labelText: 'Phone Number',
          hintText: '812345678',
          prefixIcon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/thailand_flag.png',
                  width: 24,
                  height: 16,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('🇹🇭', style: TextStyle(fontSize: 20));
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  '+66',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 24, color: Colors.grey[300]),
              ],
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _selectDate(context),
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: Icon(
              Icons.calendar_today_outlined,
              color: Theme.of(context).primaryColor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          child: Text(
            _selectedDate != null
                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                : 'Select date',
            style: TextStyle(
              color: _selectedDate != null ? Colors.black : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _hasChanges = true;
      });
      _validateForm();
    }
  }

  void _updateProfile() {
    if (_formKey.currentState!.validate()) {
      // Format phone number
      String? formattedPhone;
      final phoneText = _phoneController.text.trim();
      if (phoneText.isNotEmpty) {
        formattedPhone = '+66${_formatPhoneNumber(phoneText)}';
      }

      final updatedProfile = Profile(
        userId: widget.profile.userId,
        displayName: _displayNameController.text.trim(),
        email: widget.profile.email,
        photoUrl: widget.profile.photoUrl,
        bio: _bioController.text.trim(),
        phoneNumber: formattedPhone,
        dateOfBirth: _selectedDate,
        preferences: widget.profile.preferences,
        createdAt: widget.profile.createdAt,
        updatedAt: DateTime.now(),
      );

      context.read<ProfileBloc>().add(UpdateProfileEvent(updatedProfile));
    }
  }
}
