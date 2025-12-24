import 'package:flutter_test/flutter_test.dart';
import 'package:mult_media_picker/mult_media_picker.dart';
import 'package:mult_media_picker/mult_media_picker_platform_interface.dart';
import 'package:mult_media_picker/mult_media_picker_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMultMediaPickerPlatform
    with MockPlatformInterfaceMixin
    implements MultMediaPickerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MultMediaPickerPlatform initialPlatform = MultMediaPickerPlatform.instance;

  test('$MethodChannelMultMediaPicker is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMultMediaPicker>());
  });

  test('getPlatformVersion', () async {
    MultMediaPicker multMediaPickerPlugin = MultMediaPicker();
    MockMultMediaPickerPlatform fakePlatform = MockMultMediaPickerPlatform();
    MultMediaPickerPlatform.instance = fakePlatform;

    expect(await multMediaPickerPlugin.getPlatformVersion(), '42');
  });
}
