import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mult_media_picker/mult_media_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Picker Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MediaItem> _selectedMedias = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Media Picker Demo')),
      body: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _pickMedia(MediaType.image, false),
                child: const Text('多选图片'),
              ),
              ElevatedButton(
                onPressed: () => _pickMedia(MediaType.video, false),
                child: const Text('多选视频'),
              ),
              ElevatedButton(
                onPressed: () => _pickMedia(MediaType.image, true),
                child: const Text('单选图片'),
              ),
              ElevatedButton(
                onPressed: () => _pickMedia(MediaType.video, true),
                child: const Text('单选视频'),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text('已选择：${_selectedMedias.length}个'),
          SizedBox(height: 8),
          Text(
            '平台: ${Platform.isAndroid ? "Android (系统Photo Picker)" : "iOS (自定义UI)"}',
          ),
          Expanded(
            child: GridView.builder(
              itemCount: _selectedMedias.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final media = _selectedMedias[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    media.buildThumbnail(),
                    if (media.mediaType == MediaType.video)
                      Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _pickMedia(MediaType type, bool single) async {
    final result = await Navigator.push<List<MediaItem>>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return single
              ? MultiMediaPicker.single(mediaType: type)
              : MultiMediaPicker(mediaType: type, maxLength: 9);
        },
      ),
    );

    if (result != null) {
      setState(() {
        _selectedMedias = result;
      });
    }
  }
}
