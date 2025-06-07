import 'package:equatable/equatable.dart';

abstract class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCameraEvent extends ScannerEvent {}

class TakePictureEvent extends ScannerEvent {}

class PickImageFromGalleryEvent extends ScannerEvent {}

class RetakePictureEvent extends ScannerEvent {}

class ConfirmScanEvent extends ScannerEvent {
  final String imagePath;

  const ConfirmScanEvent(this.imagePath);

  @override
  List<Object> get props => [imagePath];
}

class ToggleFlashEvent extends ScannerEvent {}

class SwitchCameraEvent extends ScannerEvent {}

class PauseCameraEvent extends ScannerEvent {}

class ResumeCameraEvent extends ScannerEvent {}

class DisposeCameraEvent extends ScannerEvent {}
