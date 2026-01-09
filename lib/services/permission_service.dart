import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  // Request camera permission for QR scanning
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Check if camera permission is granted
  static Future<bool> isCameraPermissionGranted() async {
    return await Permission.camera.isGranted;
  }

  // Request microphone permission (optional for audio streaming)
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Show permission rationale dialog
  static Future<bool> showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Open app settings if permission is permanently denied
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  // Check and request all required permissions
  static Future<bool> checkAndRequestPermissions(BuildContext context) async {
    // Check camera permission
    bool cameraGranted = await isCameraPermissionGranted();

    if (!cameraGranted) {
      final shouldRequest = await showPermissionDialog(
        context,
        title: 'Camera Permission',
        message: 'Camera permission is required to scan QR codes.',
      );

      if (shouldRequest) {
        cameraGranted = await requestCameraPermission();
      }
    }

    if (!cameraGranted) {
      return false;
    }

    return true;
  }
}
