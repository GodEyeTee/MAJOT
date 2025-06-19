import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:my_test_app/features/ocr_scanner/presentation/pages/scanner_page.dart';
import 'package:permission_handler/permission_handler.dart';

class SimpleCameraTest extends StatefulWidget {
  const SimpleCameraTest({super.key});

  @override
  State<SimpleCameraTest> createState() => _SimpleCameraTestState();
}

class _SimpleCameraTestState extends State<SimpleCameraTest> {
  CameraController? _controller;
  String _status = 'Initializing...';
  String _errorDetails = '';
  final List<String> _debugLogs = [];
  PermissionStatus? _permissionStatus;
  List<CameraDescription>? _cameras;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _addLog(String message) {
    setState(() {
      _debugLogs.add(
        '[${DateTime.now().toString().substring(11, 19)}] $message',
      );
    });
    debugPrint('📸 CameraTest: $message');
  }

  Future<void> _initializeCamera() async {
    if (_isInitializing) {
      _addLog('Already initializing, skipping...');
      return;
    }

    _isInitializing = true;
    _debugLogs.clear();

    try {
      setState(() {
        _status = 'Checking permissions...';
      });
      _addLog('Starting camera initialization');

      // Check permission
      _permissionStatus = await Permission.camera.status;
      _addLog('Initial permission status: $_permissionStatus');

      setState(() {
        _status = 'Camera permission: $_permissionStatus';
      });

      if (!_permissionStatus!.isGranted) {
        _addLog('Requesting camera permission...');
        final result = await Permission.camera.request();
        _permissionStatus = result;
        _addLog('Permission request result: $result');

        if (!result.isGranted) {
          setState(() {
            _status = 'Camera permission denied';
          });
          return;
        }
      }

      setState(() {
        _status = 'Getting available cameras...';
      });
      _addLog('Fetching camera list...');

      // Get cameras with timeout
      _cameras = await availableCameras().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Timeout getting cameras');
        },
      );

      _addLog('Found ${_cameras?.length ?? 0} cameras');
      setState(() {
        _status = 'Found ${_cameras?.length ?? 0} cameras';
      });

      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _status = 'No cameras found on device';
        });
        return;
      }

      // List all cameras
      for (int i = 0; i < _cameras!.length; i++) {
        final cam = _cameras![i];
        _addLog('Camera $i: ${cam.name} (${cam.lensDirection})');
      }

      // Try to initialize with different settings
      await _tryInitializeController();
    } catch (e, stackTrace) {
      _addLog('Error: ${e.toString()}');
      setState(() {
        _status = 'Error: ${e.toString()}';
        _errorDetails = stackTrace.toString();
      });
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _tryInitializeController() async {
    final resolutionPresets = [
      ResolutionPreset.low,
      ResolutionPreset.medium,
      ResolutionPreset.high,
    ];

    for (final preset in resolutionPresets) {
      try {
        setState(() {
          _status = 'Trying initialization with $preset...';
        });
        _addLog('Attempting to initialize with $preset resolution');

        // Dispose previous controller if exists
        if (_controller != null) {
          await _controller!.dispose();
          _controller = null;
          await Future.delayed(const Duration(milliseconds: 500));
        }

        _controller = CameraController(
          _cameras!.first,
          preset,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _controller!.initialize().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Camera initialization timeout');
          },
        );

        _addLog('Successfully initialized with $preset!');
        setState(() {
          _status = 'Camera initialized successfully with $preset!';
        });
        return; // Success, exit loop
      } catch (e) {
        _addLog('Failed with $preset: ${e.toString()}');
        if (preset == resolutionPresets.last) {
          // Last attempt failed
          setState(() {
            _status = 'Failed to initialize with any resolution';
            _errorDetails = e.toString();
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeCamera,
            tooltip: 'Retry initialization',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _status.contains('successfully')
                              ? Icons.check_circle
                              : _status.contains('Error') ||
                                  _status.contains('denied')
                              ? Icons.error
                              : Icons.info,
                          color:
                              _status.contains('successfully')
                                  ? Colors.green
                                  : _status.contains('Error') ||
                                      _status.contains('denied')
                                  ? Colors.red
                                  : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _status,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    if (_permissionStatus != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Permission Status: ${_permissionStatus.toString().split('.').last}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Camera Preview
            if (_controller != null && _controller!.value.isInitialized) ...[
              Card(
                child: Column(
                  children: [
                    SizedBox(
                      height: 300,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: CameraPreview(_controller!),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Preview Size: ${_controller!.value.previewSize}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Resolution: ${_controller!.resolutionPreset}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Debug Logs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Debug Logs',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _debugLogs.clear();
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const Divider(),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _debugLogs.length,
                        itemBuilder: (context, index) {
                          return Text(
                            _debugLogs[index],
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.grey[800],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Error Details
            if (_errorDetails.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error Details',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.red[700]),
                      ),
                      const Divider(),
                      Text(
                        _errorDetails,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _initializeCamera,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Initialization'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScannerPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.document_scanner),
                    label: const Text('Go to Scanner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
