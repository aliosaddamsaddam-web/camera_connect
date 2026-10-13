
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

void main() {
  runApp(const CameraConnectApp());
}

class CameraConnectApp extends StatelessWidget {
  const CameraConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Camera Connect',
      theme: ThemeData.dark(),
      home: const CameraHome(),
    );
  }
}

class CameraHome extends StatefulWidget {
  const CameraHome({super.key});

  @override
  State<CameraHome> createState() => _CameraHomeState();
}

class _CameraHomeState extends State<CameraHome> {
  final RTCVideoRenderer renderer = RTCVideoRenderer();
  MediaStream? stream;
  bool active = false;
  bool ready = false;
  String message = 'الكاميرا متوقفة';

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    await renderer.initialize();
    if (!mounted) return;
    setState(() => ready = true);
  }

  Future<void> startCamera() async {
    try {
      final media = await navigator.mediaDevices.getUserMedia({
        'audio': false,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 480},
        },
      });

      if (!mounted) {
        media.getTracks().forEach((track) => track.stop());
        await media.dispose();
        return;
      }

      stream = media;
      renderer.srcObject = media;

      setState(() {
        active = true;
        message = 'الكاميرا تعمل على هذا الهاتف فقط';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => message = 'تعذر تشغيل الكاميرا: $e');
    }
  }

  Future<void> stopCamera() async {
    final media = stream;
    stream = null;

    renderer.srcObject = null;
    media?.getTracks().forEach((track) => track.stop());
    await media?.dispose();

    if (!mounted) return;
    setState(() {
      active = false;
      message = 'تم إيقاف الكاميرا';
    });
  }

  @override
  void dispose() {
    stream?.getTracks().forEach((track) => track.stop());
    stream?.dispose();
    renderer.srcObject = null;
    renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Connect'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: !ready
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : active
                        ? RTCVideoView(
                            renderer,
                            mirror: true,
                            objectFit:
                                RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          )
                        : const Center(
                            child: Icon(
                              Icons.videocam_off,
                              size: 72,
                              color: Colors.white54,
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: !ready || active ? null : startCamera,
                icon: const Icon(Icons.videocam),
                label: const Text('بدء تشغيل الكاميرا'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: active ? stopCamera : null,
                icon: const Icon(Icons.stop_circle),
                label: const Text('إيقاف الكاميرا'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}