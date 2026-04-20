import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraControllerX extends ChangeNotifier {
  CameraController? controller;
  List<CameraDescription> cameras = [];

  int currentCameraIndex = 0;
  bool isReady = false;

  Future<void> initialize() async {
    try {
      cameras = await availableCameras();

      if (cameras.isEmpty) {
        debugPrint('No cameras found');
        return;
      }

      controller = CameraController(
        cameras[currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );

      await controller!.initialize();

      isReady = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) return;

    try {
      currentCameraIndex = currentCameraIndex == 0 ? 1 : 0;

      await controller?.dispose();

      controller = CameraController(
        cameras[currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );

      await controller!.initialize();
      notifyListeners();
    } catch (e) {
      debugPrint('Switch camera error: $e');
    }
  }

  Future<void> takePhoto() async {
    if (controller == null || !controller!.value.isInitialized) return;

    try {
      await controller!.takePicture();
    } catch (e) {
      debugPrint('Take photo error: $e');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}