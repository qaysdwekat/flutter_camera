import 'package:camera/camera.dart';

enum FlashStatus {
  off,
  on,
}

extension FlashExt on FlashStatus {
  FlashStatus nextStatus() {
    switch (this) {
      case FlashStatus.off:
        return FlashStatus.on;
      case FlashStatus.on:
        return FlashStatus.off;
    }
  }

  FlashMode flashMode() {
    switch (this) {
      case FlashStatus.off:
        return FlashMode.off;
      case FlashStatus.on:
        return FlashMode.torch;
    }
  }

  String flashIcon() {
     switch (this) {
      case FlashStatus.off:
        return 'assets/icons/flash_off.svg';
      case FlashStatus.on:
        return 'assets/icons/flash_on.svg';
    }
  }
}
