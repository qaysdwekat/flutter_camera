import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/time_util.dart';
import '../utils/xfile_extension.dart';
import 'camera_media_type.dart';
import 'camera_resolution.dart';
import 'camera_service.dart';
import 'camera_type.dart';
import 'camera_zoom_level.dart';
import 'flash_status.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    this.resolution,
    this.cameraType = CameraType.back,
    this.mediaTypes = CameraMediaType.values,
    this.flashStatus = FlashStatus.off,
  });

  final List<CameraMediaType> mediaTypes;
  final CameraResolution? resolution;
  final CameraType cameraType;
  final FlashStatus flashStatus;

  @override
  State<StatefulWidget> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  List<CameraDescription> cameras = [];
  List<CameraMediaType> mediaTypes = CameraMediaType.values;
  CameraController? _cameraController;
  Future<void>? cameraValue;
  bool isRecording = false;
  bool enableRotate = false;
  Timer? _timer;
  late CameraType cameraType;
  late CameraMediaType mediaType;
  late FlashStatus flashStatus;
  late CameraZoomLevel zoom;

  @override
  void initState() {
    super.initState();
    zoom = CameraZoomLevel.one;
    cameraType = widget.cameraType;
    flashStatus = widget.flashStatus;
    mediaTypes = widget.mediaTypes.isEmpty ? CameraMediaType.values : widget.mediaTypes;
    mediaType = mediaTypes.first;

    if (CameraService().cameras.isNotEmpty) {
      initCallback(false);
    } else {
      CameraService().initAvailableCameras().then((_) {
        initCallback(true);
      });
    }
    WidgetsBinding.instance.addObserver(this);
  }

  void initCallback(invokeState) {
    cameras = CameraService().cameras;
    enableRotate = CameraService().enableRotate;
    if (cameras.isNotEmpty) {
      selectCamera(cameraType);
      if (invokeState && mounted) {
        setState(() {});
      }
    }
  }

  void selectCamera(CameraType type) {
    zoom = CameraZoomLevel.one;
    CameraDescription camera = cameras.firstWhere(
      (item) => item.lensDirection.name == type.name,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(
      camera,
      widget.resolution?.resolutionPreset ?? ResolutionPreset.max,
    );
    cameraValue = _cameraController?.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      //Exit the camera screen
      Navigator.of(context).pop(null);
      // if (isRecording) {
      //   _cameraController?.stopVideoRecording();
      // }
      // _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      selectCamera(cameraType);
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _cameraController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (mediaType == CameraMediaType.video)
              Container(
                color: Colors.black,
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                width: MediaQuery.of(context).size.width,
                child: Center(
                  child: Text(
                    TimeUtil.formatSecondsToHHMMSS(_timer?.tick ?? 0),
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  FutureBuilder(
                    future: cameraValue,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          child: CameraPreview(
                            _cameraController!,
                          ),
                        );
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    child: Column(
                      spacing: 8,
                      children: [
                        if (cameraType == CameraType.back)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.all(Radius.circular(30)),
                            ),
                            child: Row(
                              spacing: 16,
                              children: [
                                ...CameraZoomLevel.values.map(
                                  (item) => GestureDetector(
                                    onTap: () {
                                      zoom = item;
                                      setState(() {});
                                      _cameraController?.setZoomLevel(
                                        item.zoom,
                                      );
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.all(Radius.circular(30)),
                                      ),
                                      width: zoom == item ? 35 : 30,
                                      height: zoom == item ? 35 : 30,
                                      child: Text(
                                        item.zoom.toStringAsFixed(0),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.roboto(
                                          fontWeight: zoom == item ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 12,
                                          color: zoom == item ? Color(0xFFFFD60A) : Color(0xFFFFFFFF),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          color: Colors.black.withValues(alpha: 0.4),
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          width: MediaQuery.of(context).size.width,
                          child: Column(
                            spacing: 4,
                            children: [
                              MediaTypeSwitch(
                                supportedTypes: mediaTypes,
                                onChanged: (type) {
                                  setState(() {
                                    isRecording = false;
                                    mediaType = type;
                                  });
                                },
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: SvgPicture.asset(
                                      flashStatus.flashIcon(),
                                      package: 'flutter_camera',
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        flashStatus = flashStatus.nextStatus();
                                      });
                                      _cameraController?.setFlashMode(flashStatus.flashMode());
                                    },
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      switch (mediaType) {
                                        case CameraMediaType.photo:
                                          if (!isRecording) takePhoto(context);
                                          break;
                                        case CameraMediaType.video:
                                          !isRecording ? startRecording() : stopRecording();
                                          break;
                                      }
                                    },
                                    child: mediaType == CameraMediaType.video
                                        ? (isRecording
                                            ? SvgPicture.asset(
                                                'assets/icons/stop.svg',
                                                package: 'flutter_camera',
                                              )
                                            : SvgPicture.asset(
                                                'assets/icons/record.svg',
                                                package: 'flutter_camera',
                                              ))
                                        : SvgPicture.asset(
                                            'assets/icons/shutter.svg',
                                            package: 'flutter_camera',
                                          ),
                                  ),
                                  if (enableRotate)
                                    IconButton(
                                      icon: SvgPicture.asset(
                                        'assets/icons/rotate.svg',
                                        package: 'flutter_camera',
                                      ),
                                      onPressed: () async {
                                        _cameraController?.dispose();
                                        switch (cameraType) {
                                          case CameraType.front:
                                            cameraType = CameraType.back;
                                            break;
                                          case CameraType.back:
                                            cameraType = CameraType.front;
                                            break;
                                          case CameraType.extra:
                                        }
                                        selectCamera(cameraType);
                                        setState(() {});
                                      },
                                    )
                                  else
                                    const SizedBox(
                                      width: 50,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> takePhoto(BuildContext context) async {
    final navigator = Navigator.of(context);
    var file = await _cameraController?.takePicture();
    if (!kIsWeb) {
      file = await file?.rename(DateTime.now().toIso8601String());
    }
    navigator.pop(file);
  }

  void startRecording() async {
    if (!isRecording && mediaType == CameraMediaType.video) {
      await _cameraController?.startVideoRecording();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {});
      });
      isRecording = !isRecording;
      setState(() {});
    }
  }

  void stopRecording() async {
    if (isRecording) {
      final navigator = Navigator.of(context);
      var videopath = await _cameraController?.stopVideoRecording();
      if (!kIsWeb) {
        videopath = await videopath?.rename(DateTime.now().toIso8601String());
      }
      _timer?.cancel();
      isRecording = !isRecording;
      setState(() {});
      navigator.pop(videopath);
    }
  }
}

/// Extension for converting [CameraResolution] to [ResolutionPreset].
///
/// This extension provides a way to convert a [CameraResolution] value into
/// its corresponding [ResolutionPreset] value. It is useful when you need to
/// map different camera resolutions to preset values that
/// the camera API can use.
///
/// Example usage:
/// ```dart
/// CameraResolution resolution = CameraResolution.high;
/// ResolutionPreset preset = resolution.resolutionPreset;
/// ```
extension CameraResolutionExt on CameraResolution {
  /// Converts the [CameraResolution] to the corresponding [ResolutionPreset].
  ///
  /// This method maps the different camera resolution levels
  /// (low, medium, high, etc.) to the corresponding preset values available
  /// in the [ResolutionPreset] enum.
  ///
  /// Returns the appropriate [ResolutionPreset]
  /// based on the current [CameraResolution].
  ResolutionPreset get resolutionPreset {
    switch (this) {
      case CameraResolution.low:
        return ResolutionPreset.low;
      case CameraResolution.medium:
        return ResolutionPreset.medium;
      case CameraResolution.high:
        return ResolutionPreset.high;
      case CameraResolution.veryHigh:
        return ResolutionPreset.veryHigh;
      case CameraResolution.ultraHigh:
        return ResolutionPreset.ultraHigh;
      case CameraResolution.max:
        return ResolutionPreset.max;
    }
  }
}

class MediaTypeSwitch extends StatefulWidget {
  const MediaTypeSwitch({
    super.key,
    required this.supportedTypes,
    required this.onChanged,
  });
  final List<CameraMediaType> supportedTypes;
  final void Function(CameraMediaType) onChanged;

  @override
  State<StatefulWidget> createState() => _MediaTypeSwitchState();
}

class _MediaTypeSwitchState extends State<MediaTypeSwitch> {
  late CameraMediaType type;
  @override
  void initState() {
    type = widget.supportedTypes.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final selectedStyle = GoogleFonts.roboto(
      fontWeight: FontWeight.w500,
      fontSize: 14,
      color: Color(0xFFFFD60A),
    );

    final unSelectedStyle = GoogleFonts.roboto(
      fontWeight: FontWeight.normal,
      fontSize: 14,
      color: Color(0xFFFFFFFF),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        ...widget.supportedTypes.map(
          (item) => GestureDetector(
            onTap: () {
              type = item;
              widget.onChanged.call(item);
              setState(() {});
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                item.name.toUpperCase(),
                style: item == type ? selectedStyle : unSelectedStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
