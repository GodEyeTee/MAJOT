import 'package:flutter/material.dart';
import 'scanner_page.dart';

class TestCameraNavigation extends StatefulWidget {
  const TestCameraNavigation({super.key});

  @override
  State<TestCameraNavigation> createState() => _TestCameraNavigationState();
}

class _TestCameraNavigationState extends State<TestCameraNavigation> {
  int _navigationCount = 0;
  final List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_logs.length > 20) {
        _logs.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Navigation Test')),
      body: Column(
        children: [
          // Test buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _addLog('Navigating to Scanner (push)');
                    _navigationCount++;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScannerPage(),
                      ),
                    ).then((_) {
                      _addLog('Back from Scanner');
                    });
                  },
                  child: Text('Push Scanner ($_navigationCount)'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addLog('Navigating to Scanner (pushReplacement)');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScannerPage(),
                      ),
                    );
                  },
                  child: const Text('Push Replacement'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                    });
                  },
                  child: const Text('Clear Logs'),
                ),
              ],
            ),
          ),
          const Divider(),
          // Logs
          Expanded(
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Text(
                    _logs[index],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
