// lib/features/hotel/presentation/pages/create_tenant_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
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
                          helperText: 'ถ้าไม่มีบัญชี ระบบจะสร้างให้อัตโนมัติ',
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
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _createTenant,
                  child: const Text('เพิ่มผู้เช่า'),
                ),
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

      // สร้าง guest user ID ในรูปแบบ Firebase UID
      final guestUid = 'guest_${DateTime.now().millisecondsSinceEpoch}';

      final tenant = Tenant(
        id: '',
        roomId: widget.roomId,
        userId: guestUid, // ใช้ uid format
        startDate: _startDate,
        depositAmount: double.parse(_depositController.text),
        depositPaidDate: DateTime.now(),
        depositReceiver: authState.user!.displayName ?? authState.user!.email,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      context.read<TenantBloc>().add(
        CreateTenantWithUserEvent(
          tenant: tenant,
          userName: _nameController.text,
          userEmail: _emailController.text,
          userPhone:
              _phoneController.text.isNotEmpty ? _phoneController.text : null,
        ),
      );
    }
  }
}
