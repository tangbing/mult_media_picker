import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';

import 'package:mult_media_picker/src/Model.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mult_media_picker_method_channel.dart';

abstract class MultMediaPickerPlatform extends PlatformInterface {
  /// Constructs a MultMediaPickerPlatform.
  MultMediaPickerPlatform() : super(token: _token);

  static final Object _token = Object();

  static MultMediaPickerPlatform _instance = MethodChannelMultMediaPicker();

  /// The default instance of [MultMediaPickerPlatform] to use.
  ///
  /// Defaults to [MethodChannelMultMediaPicker].
  static MultMediaPickerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MultMediaPickerPlatform] when
  /// they register themselves.
  static set instance(MultMediaPickerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<Uint8List?> getThumbnail() {
    throw UnimplementedError('getThumbnail() has not been implemented.');
  }

  Future<List<Album>> getMedias(MediaItem? mediaType) {
    throw UnimplementedError('getMedias() has not been implemented.');
  }

  Future<String?> getFilePath(MediaItem item) {
    throw UnimplementedError('getFilePath() has not been implemented.');
  }

  Future<List<MediaItem>> convertToRealPaths(List<MediaItem> items) {
    throw UnimplementedError('convertToRealPaths() has not been implemented.');
  }


}
