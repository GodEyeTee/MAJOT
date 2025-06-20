import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../../../core/themes/app_spacing.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/tenant.dart';
import '../bloc/tenant/tenant_bloc.dart';

class CreateTenantPage extends StatefulWidget {
  final String roomId;

  const CreateTenantPage({super.key, required this.roomId});

  @override
  State<CreateTenantPage> createState() => _CreateTenantPageState();
}

class _CreateTenantPageState extends State<CreateTenantPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _depositController = TextEditingController();
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มผู้เช่า')),
      body: BlocListener<TenantBloc, TenantState>(
        listener: (context, state) {
          if (state is TenantSaved) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('เพิ่มผู้เช่าสำเร็จ')));
            context.pop();
          } else if (state is TenantError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
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
                        'ข้อมูลผู้เช่า',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      AppSpacing.verticalGapMd,
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อ-นามสกุล *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณาใส่ชื่อ-นามสกุล';
                          }
                          return null;
                        },
                      ),
                      AppSpacing.verticalGapMd,
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'อีเมล *',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณาใส่อีเมล';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'รูปแบบอีเมลไม่ถูกต้อง';
                          }
                          return null;
                        },
                      ),
                      AppSpacing.verticalGapMd,
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'เบอร์โทรศัพท์',
                          prefixIcon: Icon(Icons.phone),
                        ),
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
                        'ข้อมูลการเช่า',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      AppSpacing.verticalGapMd,
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('วันที่เริ่มเช่า'),
                        subtitle: Text(
                          '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked;
                            });
                          }
                        },
                      ),
                      TextFormField(
                        controller: _depositController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'เงินมัดจำ (บาท) *',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณาใส่จำนวนเงินมัดจำ';
                          }
                          if (double.tryParse(value) == null) {
                            return 'กรุณาใส่ตัวเลขเท่านั้น';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.verticalGapLg,
              BlocBuilder<TenantBloc, TenantState>(
                builder: (context, state) {
                  return SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: state is TenantSaving ? null : _createTenant,
                      child:
                          state is TenantSaving
                              ? const CircularProgressIndicator()
                              : const Text('เพิ่มผู้เช่า'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createTenant() async {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;

      // Generate unique guest ID with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final guestUserId = 'guest_${widget.roomId}_$timestamp';

      // เก็บข้อมูลผู้เช่าใน JSON
      final tenantInfo = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'created_by': authState.user!.email,
        'created_at': DateTime.now().toIso8601String(),
      };

      final tenant = Tenant(
        id: '', // จะถูก generate โดย database
        roomId: widget.roomId,
        userId: guestUserId, // ใช้ guest ID ที่ unique
        startDate: _startDate,
        depositAmount: double.parse(_depositController.text),
        depositPaidDate: DateTime.now(),
        depositReceiver: authState.user!.displayName ?? authState.user!.email,
        contractFile: jsonEncode(tenantInfo), // เก็บข้อมูลผู้เช่าเป็น JSON
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('Creating tenant for room: ${widget.roomId}');
      print('Guest user ID: $guestUserId');
      print('Tenant info: ${jsonEncode(tenantInfo)}');

      context.read<TenantBloc>().add(CreateTenantEvent(tenant));
    }
  }
}
