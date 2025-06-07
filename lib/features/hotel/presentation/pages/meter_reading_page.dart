import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/themes/app_spacing.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/meter_reading.dart';
import '../bloc/meter/meter_bloc.dart';

class MeterReadingPage extends StatefulWidget {
  final String roomId;
  final String? tenantId;

  const MeterReadingPage({super.key, required this.roomId, this.tenantId});

  @override
  State<MeterReadingPage> createState() => _MeterReadingPageState();
}

class _MeterReadingPageState extends State<MeterReadingPage> {
  final _formKey = GlobalKey<FormState>();
  final _waterController = TextEditingController();
  final _electricityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MeterBloc>().add(LoadLatestReadingEvent(widget.roomId));
  }

  @override
  void dispose() {
    _waterController.dispose();
    _electricityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('บันทึกมิเตอร์')),
      body: BlocConsumer<MeterBloc, MeterState>(
        listener: (context, state) {
          if (state is MeterSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('บันทึกมิเตอร์สำเร็จ')),
            );
            Navigator.pop(context, true);
          } else if (state is MeterError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is MeterLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
                if (state is MeterLoaded && state.latestReading != null) ...[
                  Card(
                    child: Padding(
                      padding: AppSpacing.cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ค่ามิเตอร์ล่าสุด',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          AppSpacing.verticalGapSm,
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  'น้ำ',
                                  '${state.latestReading!.waterUnits} หน่วย',
                                  Icons.water_drop,
                                  Colors.blue,
                                ),
                              ),
                              AppSpacing.horizontalGapMd,
                              Expanded(
                                child: _buildInfoItem(
                                  'ไฟฟ้า',
                                  '${state.latestReading!.electricityUnits} หน่วย',
                                  Icons.electric_bolt,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.verticalGapMd,
                ],
                Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'บันทึกมิเตอร์ใหม่',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        AppSpacing.verticalGapMd,
                        TextFormField(
                          controller: _waterController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          decoration: const InputDecoration(
                            labelText: 'มิเตอร์น้ำ',
                            prefixIcon: Icon(Icons.water_drop),
                            helperText: 'ใส่ตัวเลข 4 หลัก',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณาใส่ค่ามิเตอร์น้ำ';
                            }
                            final units = int.tryParse(value);
                            if (units == null) {
                              return 'กรุณาใส่ตัวเลขเท่านั้น';
                            }
                            if (units < 0 || units > 9999) {
                              return 'ค่ามิเตอร์ต้องอยู่ระหว่าง 0-9999';
                            }
                            if (state is MeterLoaded &&
                                state.latestReading != null) {
                              if (units < state.latestReading!.waterUnits) {
                                return 'ค่ามิเตอร์ต้องมากกว่าค่าเดิม';
                              }
                            }
                            return null;
                          },
                        ),
                        AppSpacing.verticalGapMd,
                        TextFormField(
                          controller: _electricityController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          decoration: const InputDecoration(
                            labelText: 'มิเตอร์ไฟฟ้า',
                            prefixIcon: Icon(Icons.electric_bolt),
                            helperText: 'ใส่ตัวเลข 4 หลัก',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณาใส่ค่ามิเตอร์ไฟฟ้า';
                            }
                            final units = int.tryParse(value);
                            if (units == null) {
                              return 'กรุณาใส่ตัวเลขเท่านั้น';
                            }
                            if (units < 0 || units > 9999) {
                              return 'ค่ามิเตอร์ต้องอยู่ระหว่าง 0-9999';
                            }
                            if (state is MeterLoaded &&
                                state.latestReading != null) {
                              if (units <
                                  state.latestReading!.electricityUnits) {
                                return 'ค่ามิเตอร์ต้องมากกว่าค่าเดิม';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.verticalGapLg,
                ElevatedButton(
                  onPressed: state is MeterSaving ? null : _saveReading,
                  child:
                      state is MeterSaving
                          ? const CircularProgressIndicator()
                          : const Text('บันทึก'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        AppSpacing.verticalGapXs,
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _saveReading() {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;

      final reading = MeterReading(
        id: '',
        roomId: widget.roomId,
        tenantId: widget.tenantId ?? '',
        readingMonth: DateTime.now(),
        waterUnits: int.parse(_waterController.text),
        electricityUnits: int.parse(_electricityController.text),
        recordedBy: authState.user!.id,
        createdAt: DateTime.now(),
      );

      context.read<MeterBloc>().add(SaveMeterReadingEvent(reading));
    }
  }
}
