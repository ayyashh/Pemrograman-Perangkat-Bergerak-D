import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOLO Realtime Detection',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOLO Object Detection'),
        backgroundColor: Colors.black54,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.document_scanner_outlined, size: 100, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'Welcome to YOLO Detection',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Press the button below to open the camera and start detecting objects in real-time.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const YOLODetection()),
                  );
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Start Detection'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class YOLODetection extends StatefulWidget {
  const YOLODetection({super.key});

  @override
  State<YOLODetection> createState() => _YOLODetectionState();
}

class _YOLODetectionState extends State<YOLODetection> {
  List<YOLOResult> _detections = [];
  double _fps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: Text('${_detections.length} objects'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '${_fps.toStringAsFixed(1)} FPS',
                style: const TextStyle(color: Colors.greenAccent),
              ),
            ),
          ),
        ],
      ),
      body: YOLOView(
        modelPath: 'assets/models/yolo11n_int8.tflite',
        confidenceThreshold: 0.5,
        iouThreshold: 0.45,
        lensFacing: LensFacing.back,
        showOverlays: true,
        onResult: (results) {
          setState(() => _detections = results);
        },
        onPerformanceMetrics: (metrics) {
          setState(() => _fps = metrics.fps);
        },
      ),
    );
  }
}