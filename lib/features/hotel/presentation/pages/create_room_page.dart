import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_test_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_test_app/features/auth/presentation/bloc/auth_state.dart';
import '../../../../core/themes/app_spacing.dart';
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
  final _descriptionController = TextEditingController();

  String _selectedType = 'Standard';
  final List<String> _roomTypes = ['Standard', 'Deluxe', 'Suite'];

  @override
  void dispose() {
    _roomNumberController.dispose();
    _floorController.dispose();
    _rentController.dispose();
    _sizeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มห้องใหม่')),
      body: BlocListener<RoomBloc, RoomState>(
        listener: (context, state) {
          if (state is RoomError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is RoomLoaded) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('เพิ่มห้องสำเร็จ')));
            context.pop();
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.screenPadding,
            children: [
              Card(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ข้อมูลพื้นฐาน',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      AppSpacing.verticalGapMd,
                      TextFormField(
                        controller: _roomNumberController,
                        decoration: const InputDecoration(
                          labelText: 'หมายเลขห้อง *',
                          prefixIcon: Icon(Icons.meeting_room),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณาใส่หมายเลขห้อง';
                          }
                          return null;
                        },
                      ),
                      AppSpacing.verticalGapMd,
                      TextFormField(
                        controller: _floorController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ชั้น *',
                          prefixIcon: Icon(Icons.layers),
                        ),
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
                      AppSpacing.verticalGapMd,
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'ประเภทห้อง',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items:
                            _roomTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.verticalGapMd,
              Card(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ข้อมูลเพิ่มเติม',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      AppSpacing.verticalGapMd,
                      TextFormField(
                        controller: _rentController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ค่าเช่า/เดือน (บาท) *',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
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
                      AppSpacing.verticalGapMd,
                      TextFormField(
                        controller: _sizeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ขนาด (ตร.ม.)',
                          prefixIcon: Icon(Icons.square_foot),
                        ),
                      ),
                      AppSpacing.verticalGapMd,
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'รายละเอียด',
                          prefixIcon: Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.verticalGapLg,
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _createRoom,
                  child: const Text('เพิ่มห้อง'),
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
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;

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
        description:
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
        status: RoomStatus.available,
        createdBy: authState.user!.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      context.read<RoomBloc>().add(CreateRoomEvent(room));
    }
  }
}
