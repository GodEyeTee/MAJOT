import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/app_theme_mode.dart';

abstract class ThemeState extends Equatable {
  const ThemeState();

  @override
  List<Object> get props => [];
}

class ThemeInitial extends ThemeState {}

class ThemeLoading extends ThemeState {}

class ThemeLoaded extends ThemeState {
  final AppThemeMode themeMode;
  final ThemeMode actualThemeMode;

  const ThemeLoaded({required this.themeMode, required this.actualThemeMode});

  @override
  List<Object> get props => [themeMode, actualThemeMode];
}

class ThemeError extends ThemeState {
  final String message;

  const ThemeError(this.message);

  @override
  List<Object> get props => [message];
}
