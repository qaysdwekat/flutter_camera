import 'package:camera/camera.dart';

class CameraService {
  // Factory constructor that returns the same instance every time
  factory CameraService() => _instance;

  // Private constructor to prevent direct instantiation
  CameraService._privateConstructor();

  // The single instance of CameraService
  static final CameraService _instance = CameraService._privateConstructor();

  List<CameraDescription>? _availableCameras;

  bool _enableRotate = false;
  
  // Initializes the available cameras and the camera controller
  Future<void> initAvailableCameras() async {
    try {
      // Get available cameras
      _availableCameras = await availableCameras();

      if (_availableCameras == null || _availableCameras!.isEmpty) {
        throw Exception('No cameras available.');
      }
      checkBothCamerasAvailable();
    } catch (e) {
      _availableCameras = [];
      print('Error initializing cameras: $e');
    }
  }

  // Accessor method to get the list of available cameras
  List<CameraDescription> get cameras => _availableCameras ?? [];

  void checkBothCamerasAvailable() {
    // Check if both front and back cameras are present
    bool hasFrontCamera = false;
    bool hasBackCamera = false;

    for (var camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        hasFrontCamera = true;
      } else if (camera.lensDirection == CameraLensDirection.back) {
        hasBackCamera = true;
      }
    }

    // Return true if both front and back cameras are available
    _enableRotate = hasFrontCamera && hasBackCamera;
  }

  bool get enableRotate => _enableRotate;
}
