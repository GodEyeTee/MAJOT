import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/room.dart';
import '../bloc/room/room_bloc.dart';

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumberController = TextEditingController();
  final _floorController = TextEditingController();
  final _rentController = TextEditingController();
  final _sizeController = TextEditingController();

  String _selectedType = 'Standard';
  final List<String> _roomTypes = ['Standard', 'Deluxe', 'Suite'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'เพิ่มห้องใหม่',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _createRoom,
            child: const Text(
              'บันทึก',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Basic Info
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MinimalTextField(
                      controller: _roomNumberController,
                      label: 'หมายเลขห้อง',
                      placeholder: 'เช่น 101, A201',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณาใส่หมายเลขห้อง';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _MinimalTextField(
                      controller: _floorController,
                      label: 'ชั้น',
                      placeholder: '1, 2, 3...',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณาใส่ชั้น';
                        }
                        if (int.tryParse(value) == null) {
                          return 'กรุณาใส่ตัวเลขเท่านั้น';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _MinimalDropdown(
                      label: 'ประเภทห้อง',
                      value: _selectedType,
                      items: _roomTypes,
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Pricing
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MinimalTextField(
                      controller: _rentController,
                      label: 'ค่าเช่ารายเดือน',
                      placeholder: '0',
                      keyboardType: TextInputType.number,
                      prefixText: '฿ ',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณาใส่ค่าเช่า';
                        }
                        if (double.tryParse(value) == null) {
                          return 'กรุณาใส่ตัวเลขเท่านั้น';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _MinimalTextField(
                      controller: _sizeController,
                      label: 'ขนาดห้อง (ตร.ม.)',
                      placeholder: '0',
                      keyboardType: TextInputType.number,
                      required: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createRoom() {
    if (_formKey.currentState!.validate()) {
      // Create room logic
      final room = Room(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        roomNumber: _roomNumberController.text,
        floor: int.parse(_floorController.text),
        roomType: _selectedType,
        monthlyRent: double.parse(_rentController.text),
        size:
            _sizeController.text.isNotEmpty
                ? double.parse(_sizeController.text)
                : null,
        status: RoomStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      context.read<RoomBloc>().add(CreateRoomEvent(room));
    }
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _floorController.dispose();
    _rentController.dispose();
    _sizeController.dispose();
    super.dispose();
  }
}

class _MinimalTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? prefixText;
  final bool required;

  const _MinimalTextField({
    required this.controller,
    required this.label,
    required this.placeholder,
    this.keyboardType,
    this.validator,
    this.prefixText,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(color: Colors.red[600], fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
            prefixText: prefixText,
            prefixStyle: const TextStyle(color: Colors.black87, fontSize: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black87, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[600]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _MinimalDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;

  const _MinimalDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              items:
                  items.map((String item) {
                    return DropdownMenuItem(value: item, child: Text(item));
                  }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
