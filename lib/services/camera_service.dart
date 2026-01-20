import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  CameraController? controller;
  bool isInitialized = false;

  Future<bool> initialize(List<CameraDescription> cameras) async {
    if (cameras.isEmpty) {
      print('❌ No cameras available');
      return false;
    }

    try {
      // Use front camera with low resolution (safe for device)
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        frontCamera,
        ResolutionPreset.low, // 320x240 - Very light on device
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller!.initialize();
      isInitialized = true;
      print('✅ Camera initialized (Low Res)');
      return true;
    } catch (e) {
      print('❌ Camera initialization failed: $e');
      return false;
    }
  }

  Future<String?> captureFrame() async {
    if (controller == null || !controller!.value.isInitialized) {
      print('⚠️ Camera not ready');
      return null;
    }

    try {
      final image = await controller!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      print('📸 Frame captured (${bytes.length} bytes)');
      return base64Image;
    } catch (e) {
      print('❌ Capture failed: $e');
      return null;
    }
  }

  void dispose() {
    controller?.dispose();
    isInitialized = false;
    print('📷 Camera disposed');
  }
}
