import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mult_media_picker/src/model.dart';
import 'package:mult_media_picker/src/media_picker_theme.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:ui' as ui;

const Duration _kAnimationDuration = Duration(milliseconds: 300);

class _MediaImageProvider extends ImageProvider<_MediaImageProvider> {
  final MediaItem? media;

  const _MediaImageProvider(this.media);

  @override
  Future<_MediaImageProvider> obtainKey(ImageConfiguration configuration) {
    return Future.value(this);
  }

  @override
  ImageStreamCompleter loadImage(_MediaImageProvider key,
      ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(decode),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _loadAsync(ImageDecoderCallback decode) async {
    if (media?.mediaType == MediaType.image) {
      final thumbnail = await media?.getThumbnail();
      if (thumbnail != null) {
        return decode(await ui.ImmutableBuffer.fromUint8List(thumbnail));
      }
      throw Exception('Failed to load image');
    } else {
      final thumbnail = await media?.getThumbnail();
      if (thumbnail != null) {
        return decode(await ui.ImmutableBuffer.fromUint8List(thumbnail));
      }
      throw Exception('Failed to load video thumbnail');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _MediaImageProvider && other.media?.path == media?.path;

  @override
  // TODO: implement hashCode
  int get hashCode => media?.path.hashCode ?? -1;
}

class MultiMediaPreview extends StatefulWidget {

  final List<MediaItem>? selectedMedias;
  final List<MediaItem>? allMedias;
  final int? initIndex;
  final bool? isSingleMode;
  final int? maxLength;
  final bool? isAlbumMode;
  final MediaPickerTheme? theme;

  const MultiMediaPreview._({
    super.key,
    this.selectedMedias,
    this.allMedias,
    this.initIndex,
    this.isSingleMode,
    this.maxLength,
    this.isAlbumMode,
    this.theme
  });

  static Future<List<MediaItem>?> preview(BuildContext context,
      List<MediaItem>? selectedMedias,
      bool? isSingleMode,
      int? maxLength,
      MediaPickerTheme? theme,) {
    return Navigator.push(context, MaterialPageRoute(builder: (context) {
      return MultiMediaPreview._(
        selectedMedias: selectedMedias,
        isSingleMode: isSingleMode,
        maxLength: maxLength,
        isAlbumMode: false,
        theme: theme,
      );
    }));
  }

  static Future<List<MediaItem>?> previewAlbum(BuildContext context,
      List<MediaItem>? allMedias,
      int? initIndex,
      List<MediaItem>? selectedMedias,
      bool? isSingleMode,
      int? maxLength,
      MediaPickerTheme? theme,) {
    return Navigator.push(context, MaterialPageRoute(builder: (context) {
      return MultiMediaPreview._(
        selectedMedias: selectedMedias,
        allMedias: allMedias,
        initIndex: initIndex,
        isSingleMode: isSingleMode,
        maxLength: maxLength,
        isAlbumMode: true,
        theme: theme,
      );
    }));
  }

  @override
  State<MultiMediaPreview> createState() => _MultiMediaPreviewState();
}

class _MultiMediaPreviewState extends State<MultiMediaPreview>
    with SingleTickerProviderStateMixin {

  final _unselectedMedias = <MediaItem>[];
  List<MediaItem>? _allMedias;
  List<MediaItem>? _selectedMedias;
  AnimationController? _animation;
  PageController? _pageController;

  int get initIndex => widget.initIndex ?? 0;

  int get _pageIndex {
    if (_pageController?.hasClients == true) {
      return _pageController!.page!.toInt();
    }
    return initIndex;
  }

  MediaItem get _pageMedia => _allMedias![_pageIndex];

  bool get _isSelected => widget.selectedMedias?.contains(_pageMedia) == true;

  @override
  void initState() {
    super.initState();
    _allMedias = List<MediaItem>.unmodifiable(
        widget.allMedias ?? widget.selectedMedias ?? []);
    _selectedMedias = List<MediaItem>.from(widget.selectedMedias ?? []);
    _animation = AnimationController(duration: kThemeAnimationDuration, vsync: this);
    _pageController = PageController(initialPage: initIndex)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animation?.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    final themeData = Theme.of(context);
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (_animation?.isCompleted == true) {
              _animation?.reverse();
            } else {
              _animation?.forward();
            }
          },
          child: PhotoViewGallery.builder(
              itemCount: _allMedias?.length ?? 0,
              backgroundDecoration: const BoxDecoration(),
              pageController: _pageController,
              builder: (context, index) {
                final media = _allMedias?[index];
                return PhotoViewGalleryPageOptions
                    .customChild(child:
                Stack(
                  alignment: Alignment.center,
                  children: [
                    PhotoView(imageProvider: _MediaImageProvider(media),
                      initialScale: PhotoViewComputedScale.contained,
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 2,
                    ),
                    if (media?.mediaType == MediaType.video) const Icon(
                        Icons.play_circle_outline, size: 64,
                        color: Colors.white70)
                  ],
                ));
              }),
        ),
        Column(
          children: [
            SlideTransition(position: Tween<Offset>(
                begin: Offset.zero, end: const Offset(0.0, -1.0))
                .animate(CurvedAnimation(
                parent: _animation!, curve: Curves.fastOutSlowIn)),
              child: AppBar(
                elevation: 0.5,
                backgroundColor: widget.theme?.appBarBgColor,
                leading: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  child: Center(child: widget.theme?.appBarBack ??
                      const Icon(Icons.arrow_back_ios)),
                  onTap: () => Navigator.maybePop(context),
                ),
                title: Text(
                  '${_pageIndex + 1}/${_allMedias!.length}',
                  style: TextStyle(color: widget.theme?.appBarTextColor),
                ),
                actions: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (widget.isAlbumMode == true) {
                        if (_isSelected) {
                          _selectedMedias!.remove(_pageMedia);
                        } else {
                          _selectedMedias!.add(_pageMedia);
                        }
                      } else {
                        if (_isSelected) {
                          _unselectedMedias.add(_pageMedia);
                        } else {
                          _unselectedMedias.remove(_pageMedia);
                        }
                      }
                      widget.selectedMedias!
                        ..clear()
                        ..addAll(_selectedMedias!)
                        ..removeWhere(_unselectedMedias.contains);
                      setState(() {});
                    },
                    child: AnimatedContainer(
                      width: 24.0,
                      height: 24.0,
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      duration: _kAnimationDuration,
                      decoration: BoxDecoration(
                        border: !_isSelected ? Border.all(
                            color: Colors.white54, width: 1.0) : null,
                        color: _isSelected ? widget.theme?.selectedColor ??
                            themeData.primaryColorDark : Colors.black26,
                        gradient: _isSelected
                            ? widget.theme?.selectedGradient
                            : null,
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedSwitcher(
                          duration: _kAnimationDuration,
                          child: _isSelected ? widget.isSingleMode == true ?
                          Icon(Icons.check, size: 18.0, color: widget.theme
                              ?.selectedTextColor ?? Colors.white) :
                          Text('${1 + _selectedMedias!.indexOf(_pageMedia)}',
                            style: TextStyle(
                              color: widget.theme?.selectedTextColor ??
                                  Colors.white,
                              fontSize: 17.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ) : const SizedBox.shrink()
                      ),
                    ),
                  )
                ],
              ),
            ),
            const Spacer(),
            SlideTransition(
              position: Tween<Offset>(begin: Offset.zero, end: Offset(0.0, 1.0))
                  .animate(CurvedAnimation(
                  parent: _animation!, curve: Curves.fastOutSlowIn)),
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: Container(
                  color: Colors.white,
                  child: SafeArea(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 79.0,
                            child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7.5),
                                physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics()),
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedMedias?.length ?? 0,
                                itemBuilder: (context, index) {
                                  final media = _selectedMedias?[index];
                                  return GestureDetector(
                                    child: AnimatedContainer(
                                      duration: _kAnimationDuration,
                                      margin: EdgeInsets.all(7.5),
                                      foregroundDecoration: BoxDecoration(
                                          border: media == _pageMedia
                                              ? Border.all(color: widget.theme
                                              ?.selectedColor ??
                                              themeData.primaryColor, width: 3)
                                              : null,
                                          color: widget.selectedMedias!
                                              .contains(media) ? Colors
                                              .transparent : Colors.white30
                                      ),
                                      child: media?.buildThumbnail(
                                          width: 64.0, height: 64.0),
                                    ),
                                    onTap: () {
                                      if (media == null) return;
                                      if (_allMedias?.contains(media) ?? false) {
                                        _pageController?.jumpToPage(
                                            _allMedias?.indexOf(media) ?? 0);
                                      }
                                    },
                                  );
                                }),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 7.5),
                            child: Row(
                              children: [
                                Spacer(),
                                if (widget.theme?.confirm == null)
                                  CupertinoButton(
                                    color: themeData.primaryColor,
                                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                                      minimumSize: Size(0, 34.0),
                                      onPressed: widget.selectedMedias?.isEmpty == true ?
                                      null : () => Navigator.pop(context, widget.selectedMedias),
                                      child: Text(
                                        '确定(${widget.selectedMedias!.length}/${widget.maxLength})',
                                        style: const TextStyle(fontSize: 17.0, color: Colors.white),
                                      )
                                  )
                                else
                                  widget.theme!.confirm!(
                                    '确定(${widget.selectedMedias!.length}/${widget.maxLength})',
                                    widget.selectedMedias?.isEmpty == true ? null : () => Navigator.pop(context, widget.selectedMedias)
                                  ),
                                SizedBox(width: 16.0,)
                              ],
                            ),
                          ),
                        ],
                      )
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}
