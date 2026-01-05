import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mult_media_picker/src/model.dart';
import 'package:mult_media_picker/src/media_picker_theme.dart';
import 'package:mult_media_picker/src/multi_media_preview.dart';

import 'mult_media_picker_platform_interface.dart';

// class MultMediaPicker {
//
//   final Media
//
//   Future<String?> getPlatformVersion() {
//     return MultMediaPickerPlatform.instance.getPlatformVersion();
//   }
// }

const Duration _kAnimationDuration = Duration(milliseconds: 300);

class MultiMediaPicker extends StatefulWidget {
  final MediaType mediaType;
  final List<MediaItem>? selectedMedias;
  final bool isSingleMode;
  final int maxLength;
  final MediaPickerTheme? theme;

  const MultiMediaPicker({
    super.key,
    required this.mediaType,
    this.selectedMedias,
    this.isSingleMode = false,
    this.maxLength = 9,
    this.theme,
  }) : assert(maxLength > 1);

  const MultiMediaPicker.single({
    super.key,
    required this.mediaType,
    this.selectedMedias,
    this.isSingleMode = true,
    this.maxLength = 1,
    this.theme,
  });

  // /// Android: 直接使用系统 Photo Picker（符合 Google Play 政策）

  @override
  State<MultiMediaPicker> createState() => _MultiMediaPickerState();
}

class _MultiMediaPickerState extends State<MultiMediaPicker>
    with SingleTickerProviderStateMixin {
  AnimationController? _albumsAnimation;
  Future<List<Album>>? _albumsFuture;
  Album? _currentAlbum;
  List<MediaItem>? _selectedMedias;

  bool get _albumsShown =>
      _albumsAnimation?.status == AnimationStatus.completed;

  @override
  void initState() {
    super.initState();
    _selectedMedias = List.of(widget.selectedMedias ?? []);
    _albumsAnimation = AnimationController(
      duration: _kAnimationDuration,
      vsync: this,
    );

    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) => _pickAndroidMedia(),
      );
    } else {
      setState(() {
        _refreshMedias();
      });
    }
  }

  Future<void> _pickAndroidMedia() async {
    var result = await MultMediaPickerPlatform.instance.getMedias(
      mediaType: widget.mediaType,
      maxCount: widget.maxLength,
      isSingle: widget.isSingleMode,
    );
    if (mounted) {
      Navigator.pop(context, result.medias.isEmpty ? null : result.medias);
    }
  }

  void _refreshMedias() {
    _albumsFuture = MultMediaPickerPlatform.instance
        .getMedias(
          mediaType: widget.mediaType,
          maxCount: widget.maxLength,
          isSingle: widget.isSingleMode,
        )
        .then((value) {
          if (value.albums.isNotEmpty) {
            _currentAlbum = value.albums.first;
          }
          return value.albums;
        });
  }

  @override
  void dispose() {
    _albumsAnimation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Android 显示加载中，等待系统 Picker
    if (Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: widget.theme?.appBarBgColor,
          leading: IconButton(onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close)),
        ),
      );
    }

    final themeData = Theme.of(context);
    return FutureBuilder<List<Album>>(
      future: _albumsFuture,
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            elevation: 0.5,
            backgroundColor: widget.theme?.appBarBgColor,
            leading: AnimatedBuilder(
              animation: _albumsAnimation!,
              builder: (context, child) {
                return AnimatedSwitcher(
                  duration: _kAnimationDuration,
                  child: GestureDetector(
                    key: Key('$_albumsShown'),
                    behavior: HitTestBehavior.translucent,
                    child: Center(
                      child: _albumsShown
                          ? widget.theme?.appBarBack ??
                                const Icon(Icons.arrow_back_ios)
                          : widget.theme?.appBarClose ?? const Icon(Icons.close),
                    ),
                    onTap: () {
                      if (_albumsShown) {
                        _albumsAnimation?.reverse();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                );
              },
            ),
            title: _currentAlbum == null
                ? null
                : GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    child: Text.rich(
                      TextSpan(
                        text: _currentAlbum?.alias,
                        children: [
                          const WidgetSpan(child: SizedBox(width: 5)),
                          WidgetSpan(
                            child: RotationTransition(
                              turns: _albumsAnimation!.drive(
                                Tween(begin: 0.0, end: -0.5),
                              ),
                              child: Transform.rotate(
                                angle: widget.theme?.appBarArrowDown == null
                                    ? pi / 2
                                    : 0,
                                child:
                                    widget.theme?.appBarArrowDown ??
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: themeData
                                          .primaryTextTheme
                                          .titleLarge
                                          ?.color,
                                      size: themeData
                                          .primaryTextTheme
                                          .titleLarge
                                          ?.fontSize,
                                    ),
                              ),
                            ),
                            alignment: PlaceholderAlignment.middle,
                          ),
                        ],
                      ),
                      style: themeData.primaryTextTheme.titleLarge
                          ?.copyWith(color: widget.theme?.appBarTextColor),
                    ),
              onTap: () {
                if (_albumsShown) {
                  _albumsAnimation?.reverse();
                } else {
                  _albumsAnimation?.forward();
                }
              },
                  ),
          ),
          body: _buildBody(context, snapshot),
        );
      }
    );
  }

  Widget _buildBody(BuildContext context, AsyncSnapshot<List<Album>> snapshot) {
      if (snapshot.hasData && snapshot.data?.isNotEmpty == true) {
        return _buildContent(context, snapshot.data!, _currentAlbum!);
      } else if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CupertinoActivityIndicator());
      } else if (snapshot.hasError) {
        return const Center(child: Icon(Icons.error_outline));
      }
      return const Center(child: Text('没有媒体文件'));
  }

  Widget _buildContent(BuildContext context, List<Album> albums, Album album) {
    final themeData = Theme.of(context);
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
                child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                    ),
                    itemCount: album.medias.length,
                    itemBuilder: (context, index) {
                      final media = album.medias[index];
                      final selectedIndex = _selectedMedias?.indexOf(media) ?? -1;
                      return GestureDetector(
                        onTap: () async {
                            final result = await MultiMediaPreview.previewAlbum(
                                context,
                                album.medias,
                                index,
                                _selectedMedias,
                                widget.isSingleMode,
                                widget.maxLength,
                                widget.theme
                            );

                            if (result != null) {
                              Navigator.of(context).pop(result);
                            } else {
                              setState(() {});
                            }
                        },
                        child: _MediaItem(
                            media: media,
                            isSingleModel: widget.isSingleMode,
                            isSelected: selectedIndex != -1,
                            selectedIndex: selectedIndex + 1,
                            selectedTextColor: widget.theme?.selectedTextColor,
                            selectedColor: widget.theme?.selectedColor,
                            selectedGradient: widget.theme?.selectedGradient,
                            onCheckTap: () {
                              if (selectedIndex == -1) {
                                if ((_selectedMedias?.length ?? 0) >= widget.maxLength) {
                                  return;
                                }
                                _selectedMedias?.add(media);
                              } else {
                                _selectedMedias?.removeAt(selectedIndex);
                              }
                              setState(() {});
                            },
                        ),
                      );
                    })),
            Container(
              color: Colors.white,
              child: SafeArea(
                  child: Padding(padding: EdgeInsets.symmetric(vertical: 7.5),
                    child: Row(
                      children: [
                        if (widget.theme?.preview == null)
                          CupertinoButton(
                              onPressed: _selectedMedias?.isEmpty == true ? null : _showPreview,
                              child: Text('阅览', style: TextStyle(fontSize: 17.0)),
                          )
                        else
                          widget.theme!.preview!(_selectedMedias?.isEmpty == true ? null : _showPreview),
                        Spacer(),
                        if (widget.theme?.confirm == null)
                          CupertinoButton(
                              color: themeData.primaryColor,
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              minSize: 34.0,
                              onPressed: _selectedMedias?.isEmpty == true ? null : () => _confirmAndPop(_selectedMedias!),
                              child: Text('确定(${_selectedMedias!.length}/${widget.maxLength})',
                                style: TextStyle(fontSize: 17.0, color: Colors.white))
                          )
                        else
                          widget.theme!.confirm!(
                            '确定(${_selectedMedias!.length}/${widget.maxLength})',
                            _selectedMedias?.isEmpty == true ? null : () => Navigator.pop(context, _selectedMedias)
                          ),
                        const SizedBox(width: 16.0),
                      ],
                    ),
                  )
              ),
            )
          ],
        ),
        ..._buildAlbumMenu(albums),
      ],
    );
  }

  List<Widget> _buildAlbumMenu(List<Album> albums) {
    return [
      AnimatedBuilder(
          animation: _albumsAnimation!,
          builder: (context, child) {
            return IgnorePointer(
              ignoring: !_albumsShown,
              child: GestureDetector(
                onTap: () => _albumsAnimation?.reverse(),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45 * _albumsAnimation!.value)
                  ),
                ),
              ),
            );
          }),
      LayoutBuilder(builder: (context, constraints) {
         return Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             SlideTransition(position: _albumsAnimation!.drive(
                 Tween<Offset>(begin: Offset(0.0, -1.0), end: Offset.zero)),
               child: ClipRRect(
                 borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                 child: Container(
                   constraints: BoxConstraints(maxHeight: constraints.maxHeight * 2 /3),
                   decoration: BoxDecoration(color: Colors.white),
                   child: MediaQuery.removePadding(
                       context: context,
                       removeTop: true,
                       removeBottom: true,
                       child: ListView.builder(
                         shrinkWrap: true,
                         physics: AlwaysScrollableScrollPhysics(
                           parent: BouncingScrollPhysics()
                         ),
                         itemCount: albums.length,
                         itemBuilder: (context, index) {
                            final item = albums[index];
                            return GestureDetector(
                              onTap: () {
                                 setState(() {
                                   _currentAlbum = item;
                                 });
                                 _albumsAnimation?.reverse();
                              },
                              child: _AlbumItem(album: item, arrowRight: widget.theme?.arrowRight ?? SizedBox.shrink()),
                            );

                       })
                   ),
                 ),
               ),
             )
           ],
         );
      }),
    ];
  }

  Future<void> _showPreview() async {
      final result = await MultiMediaPreview.preview(
          context,
          _selectedMedias,
          widget.isSingleMode,
          widget.maxLength,
          widget.theme
      );
      if (result != null) {
        _confirmAndPop(result);
      } else {
        setState(() {});
      }
  }

  Future<void> _confirmAndPop(List<MediaItem> items) async {
     if (Platform.isIOS) {
       final converted = await MultMediaPickerPlatform.instance.convertToRealPaths(items);
       if (mounted) Navigator.pop(context, converted);
     } else {
       Navigator.pop(context, items);
     }
  }

}


class _AlbumItem extends StatelessWidget {
  final Album album;
  final Widget? arrowRight;

  const _AlbumItem({super.key, required this.album, this.arrowRight});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: IntrinsicHeight(
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.all(Radius.circular(4)),
              child: album.medias.first.buildThumbnail(width: 60, height: 60),
            ),
            SizedBox(width: 10),
            Expanded(child:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(album.alias, style: themeData.textTheme.titleMedium),
                Text('${album.medias.length}', style: themeData.textTheme.titleMedium),
              ],
            )),
            arrowRight ?? Icon(Icons.arrow_forward_ios,
              size: themeData.textTheme.titleMedium?.fontSize,
              color: themeData.textTheme.bodySmall?.color)
          ],
        ),
      ),
    );
  }
}





class _MediaItem extends StatelessWidget {
  final MediaItem media;
  final bool isSingleModel;
  final bool isSelected;
  final int? selectedIndex;
  final VoidCallback? onCheckTap;
  final Color? selectedTextColor;
  final Color? selectedColor;
  final Gradient? selectedGradient;

  const _MediaItem({
    super.key,
    required this.media,
    required this.isSingleModel,
    required this.isSelected,
    this.selectedIndex,
    this.onCheckTap,
    this.selectedTextColor,
    this.selectedColor,
    this.selectedGradient
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
     return Stack(
       children: [
         media.buildThumbnail(width: constraints.maxWidth, height: constraints.maxHeight),
         Positioned.fill(
             child: AnimatedContainer(
                 duration: _kAnimationDuration,
                 color: isSelected ? Colors.white30 : Colors.transparent,
             )),
         if (media.mediaType == MediaType.video)
           Align(
             alignment: AlignmentDirectional.bottomEnd,
             child: Padding(padding: EdgeInsets.all(5.0),
               child: Icon(Icons.play_circle_outline, color: Colors.white30, size: 20),
             ),
           ),
         Align(
           alignment: AlignmentDirectional.topEnd,
           child: GestureDetector(
             behavior: HitTestBehavior.opaque,
             onTap: onCheckTap,
             child: AnimatedContainer(
               width: 24.0,
               height: 24.0,
                 margin: EdgeInsets.all(4.0),
                 duration: _kAnimationDuration,
               decoration: BoxDecoration(
                 border: !isSelected ? Border.all(color: Colors.white54, width: 1.0) : null,
                 color: isSelected ? selectedColor ?? themeData.primaryColor : Colors.black26,
                 gradient: selectedGradient,
                 shape: BoxShape.circle,
               ),
               child: AnimatedSwitcher(
                   duration: _kAnimationDuration,
                 child: isSelected
                     ? isSingleModel
                     ? Icon(Icons.check, size: 18.0, color: selectedTextColor ?? Colors.white54) :
                     Text(
                       '$selectedIndex',
                       style: TextStyle(
                         color: selectedTextColor ?? Colors.white
                       ),
                     )
                     : const SizedBox.shrink()
               ),
             ),
           ),
         ),
       ],
     );
    });
  }
}
