import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mult_media_picker/src/model.dart';

import './mult_media_picker_platform_interface.dart';

/// An implementation of [MultMediaPickerPlatform] that uses method channels.
class MethodChannelMultMediaPicker extends MultMediaPickerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mult_media_picker');

  @override
  Future<PickMediaResult> getMedias({
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

      if (result == null) {
        print('getMedias result null');
        return PickMediaResult();
      }

        if (Platform.isIOS) {
          final albums = <Album>[];
          for (final albumData in result) {
            final map = Map<String, dynamic>.from(albumData);
            final mediasData = map['media'] as List? ?? [];
            final medias = mediasData.map((e) {
              final mediaMap = Map<String, dynamic>.from(e);
              return MediaItem(
                path: mediaMap['id']?.toString() ?? '',
                mediaType: mediaMap['mediaType'] == 1
                    ? MediaType.video
                    : MediaType.image,
                dateModified: _safeToInt(mediaMap['dateCreate']),
                isAsset: true,
                width: _safeToInt(mediaMap['width']),
                height: _safeToInt(mediaMap['height']),
                duration: _safeToInt(mediaMap['duration']),
              );
            }).toList();
            if (medias.isNotEmpty) {
              albums.add(Album(name: map['name'] ?? 'Unknow', medias: medias));
            }
          }
          albums.sort((a, b) => b.sort.compareTo(a.sort));
          return PickMediaResult(albums: albums);
        } else {
          var albums = result.map((e) {
            final map = Map<String, dynamic>.from(e);
            return MediaItem(
              path: map['path']?.toString() ?? '',
              mediaType: map['mediaType'] == 1
                  ? MediaType.video
                  : MediaType.image,
              width: _safeToInt(map['width']),
              height: _safeToInt(map['height']),
              duration: _safeToInt(map['duration']),
            );
          }).toList();
          return PickMediaResult(medias: albums);
        }
    } catch (e) {
      print('Error picking media: $e');
      return PickMediaResult();
    }
  }

  @override
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

  @override
  Future<List<MediaItem>> convertToRealPaths(List<MediaItem> items) async {
    final results = <MediaItem>[];
    for (final item in items) {
      final realPath = await getFilePath(item);
      if (realPath != null) {
        // 保留原始 assetId 用于视频缩略图
        results.add(
          item.copyWith(path: realPath, isAsset: false, assetId: item.path),
        );
      }
    }
    return results;
  }

  int _safeToInt(dynamic value) {
    if (value == null) return 0;
    double? v = value is int ? value.toDouble() : (value as double?);
    if (v == null || v.isNaN || v.isInfinite) return 0;
    return v.toInt();
  }
}
