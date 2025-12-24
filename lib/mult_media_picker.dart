
import 'mult_media_picker_platform_interface.dart';

class MultMediaPicker {
  Future<String?> getPlatformVersion() {
    return MultMediaPickerPlatform.instance.getPlatformVersion();
  }
}
