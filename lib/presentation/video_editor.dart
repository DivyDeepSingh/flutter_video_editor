import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../models/video_segment.dart';
import '../services/ffmpeg_service.dart';
import '../widgets/thumbnail_cropper.dart';

class VideoEditorPage extends StatefulWidget {
  final String videoPath;
  const VideoEditorPage({super.key, required this.videoPath});

  @override
  State<VideoEditorPage> createState() => _VideoEditorPageState();
}

class _VideoEditorPageState extends State<VideoEditorPage> {
  late VideoPlayerController _controller;
  List<VideoSegment> segments = [];
  Duration videoDuration = Duration.zero;

  double startPercent = 0.0;
  double endPercent = 1.0;
  List<Image> thumbnails = [];

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) async {
        videoDuration = _controller.value.duration;
        segments = [
          VideoSegment(start: Duration.zero, end: _controller.value.duration),
        ];
        setState(() {});
        await generateThumbnails();
      });
  }

  Future<void> generateThumbnails() async {
    const thumbCount = 10;
    final List<Image> tempThumbs = [];
    for (int i = 0; i < thumbCount; i++) {
      final t = (_controller.value.duration.inMilliseconds / thumbCount) * i;
      final path = await VideoThumbnail.thumbnailFile(
        video: widget.videoPath,
        imageFormat: ImageFormat.PNG,
        timeMs: t.toInt(),
        maxWidth: (MediaQuery.of(context).size.width * 0.08).toInt(),
        quality: 70,
        maxHeight: 100,
      );
      if (path != null) tempThumbs.add(Image.file(File(path)));
    }
    thumbnails = tempThumbs;
    setState(() {});
  }

  void _playSelectedRange() {
    if (!_controller.value.isInitialized) return;
    final start = Duration(
        milliseconds: (videoDuration.inMilliseconds * startPercent).toInt());
    final end = Duration(
        milliseconds: (videoDuration.inMilliseconds * endPercent).toInt());
    _controller.seekTo(start);
    _controller.play();

    _controller.addListener(() {
      final pos = _controller.value.position;
      if (pos >= end) _controller.seekTo(start);
    });
  }

  Future<void> exportVideo() async {
    final start = Duration(
        milliseconds: (videoDuration.inMilliseconds * startPercent).toInt());
    final end = Duration(
        milliseconds: (videoDuration.inMilliseconds * endPercent).toInt());
    segments = [VideoSegment(start: start, end: end)];

    final outputPath = await FFmpegService.exportVideo(
      widget.videoPath,
      segments,
      onLog: (s) => print(s),
    );

    if (outputPath != null) {
      print(outputPath);
      playTheEditedVideo(outputPath);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Exported: $outputPath')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Export failed')));
    }
  }

  void playTheEditedVideo(String path) {
    _controller.pause();
    _controller.dispose();
    _controller = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.of(context).size.width * 0.90;

    return Scaffold(
      appBar: AppBar(title: const Text("Video Editor")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_controller.value.isInitialized)
              AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller)),
            const SizedBox(height: 10),
            Container(
              // width: 200,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ThumbnailCropper(
                startPercent: startPercent,
                endPercent: endPercent,
                width: viewportWidth,
                thumbnails: thumbnails,
                onStartChanged: (v) => setState(() {
                  startPercent = v.clamp(0.0, endPercent - 0.05);
                  _playSelectedRange();
                }),
                onEndChanged: (v) => setState(() {
                  endPercent = v.clamp(startPercent + 0.05, 1.0);
                  _playSelectedRange();
                }),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_controller.value.isPlaying)
                      _controller.pause();
                    else
                      _playSelectedRange();
                    setState(() {});
                  },
                  child: Text(_controller.value.isPlaying ? 'Pause' : 'Play'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                    onPressed: exportVideo, child: const Text('Export')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
