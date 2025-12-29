
import 'mult_media_picker_platform_interface.dart';

class MultMediaPicker {

  final Media

  Future<String?> getPlatformVersion() {
    return MultMediaPickerPlatform.instance.getPlatformVersion();
  }
}
