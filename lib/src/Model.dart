

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum MediaType { image, video }

class PickMediaResult {
  final List<Album> albums; // ios
  final List<MediaItem> medias; // Android

  PickMediaResult({this.albums = const [], this.medias = const []});
}

class MediaItem {
  final String path;
  final MediaType mediaType;
  final int? dateModified;
  final bool isAsset;
  final String? assetId; // IOS 原始 localIdentifier，用于获取视频
  Uint8List? _thumbnail;
  final int width;
  final int height;
  final int duration; // 视频秒数，图片为 0


  static const _channel = MethodChannel('multi_media_picker');


  MediaItem({
   required this.path,
   required this.mediaType,
   this.dateModified,
   this.isAsset = false,
    this.assetId,
    this.width = 0,
    this.height = 0,
    this.duration = 0,
});

  MediaItem copyWith({
    String? path,
    bool? isAsset,
    String? assetId,
    int? width,
    int? height,
    int? duration,
}) {
    return MediaItem(
        path: path ?? this.path,
        mediaType:  mediaType,
        dateModified: dateModified,
        isAsset: isAsset ?? this.isAsset,
        assetId: assetId ?? this.assetId,
        width: width ?? this.width,
        height: height ?? this.height,
        duration: duration ?? this.duration,
    );
  }

  Future<Uint8List?> getThumbnail() async {
    if (_thumbnail != null) return _thumbnail;
    try {
      // 视频用 assetId 获取缩略图
      final thumbnailPath = (mediaType == MediaType.video && assetId != null) ? assetId : path;

      _thumbnail = await _channel.invokeMethod<Uint8List>('getThumbnail', {
        'path': thumbnailPath,
        'mediaType': mediaType.index,
        'isAsset': isAsset || assetId != null,
      });
    } catch (e) {
      print('Error getting thumbnail: $e');
    }
    return _thumbnail;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is MediaItem && path == other.path;
  }

  @override
  int get hashCode => path.hashCode;

}

class Album {
  final String name;
  final List<MediaItem> medias;

  Album({required this.name, required this.medias});

  String get alias {
    if (Platform.isAndroid) {
      if (name == '#Recents') return '图片和视频';
      if (name == '#Videos') return '所有视频';
      if (name == 'Screenshots') return '截屏';
      if (name == 'Camera') return '相机';
    } else if(Platform.isIOS) {
      if (name == 'Recents' || name == '最近项目') return '最近项目';
      if (name == 'Favorites' || name == '个人收藏') return '个人收藏';
    }
    return name;
  }

  int get sort {
    if (Platform.isAndroid) {
      if (name == '#Recents') return 1000;
      if (name == '#Videos') return 999;
      if (name == 'Camera') return 998;
    } else if (Platform.isIOS) {
      if (name == 'Recents' || name == '最近项目') return 1000;
      if (name == 'Favorites' || name == '个人收藏') return 999;
    }
    return 0;
  }

}