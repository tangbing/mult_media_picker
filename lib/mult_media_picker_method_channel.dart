import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mult_media_picker/src/Model.dart';

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

  Future<Uint8List?> getThumbnail(MediaType mediaType) {
      final thumbnailPath = (mediaType == MediaType.video && assetId != null)
  }

  Future<List<Album>> getMedias({
    MediaType? mediaType,
    int maxCount = 9,
    bool isSingle = false,
}) async {
    try {
      final result = await methodChannel.invokeMethod<List>('pickMedia', {
        'mediaType': mediaType?.index,
        'maxCount': maxCount,
        'isSingle': isSingle,
      });

      if (result == null) return [];

      return result.map((m) {
        final map = Map<String, dynamic>.from(m);
        return MediaItem(
            path: path,
            mediaType: mediaType
        );
      });

    } catch (e) {
      print('Error picking media: $e');
      return [];
    }
  }

  Future<String?> getFilePath(MediaItem item) async {
    if (!Platform.isIOS || !item.isAsset) return item.path;
    try {
      return await methodChannel.invokeMethod<String>('getFilePath', {
        'assetId': item.path,
        'mediaType': item.mediaType.index,
      });
    } catch (e) {
      print('Error getting file path: $e');
      return null;
    }
  }

  Future<List<MediaItem>> convertToRealPaths(List<MediaItem> items) {

  }



}
