import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mult_media_picker_platform_interface.dart';

/// An implementation of [MultMediaPickerPlatform] that uses method channels.
class MethodChannelMultMediaPicker extends MultMediaPickerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mult_media_picker');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
