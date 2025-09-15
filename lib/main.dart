// import 'dart:io';
// import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter_new/return_code.dart';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:video_player/video_player.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;

// /// -------------------- VideoSegment --------------------
// class VideoSegment {
//   Duration start;
//   Duration end;
//   VideoSegment({required this.start, required this.end});
// }

// /// -------------------- FFmpegService --------------------
// class FFmpegService {
//   static Future<bool> _runFfmpeg(
//     List<String> args, {
//     void Function(String)? onLog,
//     bool throwOnFail = false,
//   }) async {
//     final cmd = args.map((s) => s.contains(' ') ? '"$s"' : s).join(' ');
//     onLog?.call("\n\n\$ ffmpeg $cmd\n");
//     final session = await FFmpegKit.execute(args.join(' '));
//     final rc = await session.getReturnCode();
//     final logs = await session.getOutput();
//     if (logs?.isNotEmpty == true) onLog?.call(logs!);
//     final ok = ReturnCode.isSuccess(rc);
//     onLog?.call("=> ${ok ? 'OK' : 'FAILED'} (code: ${rc?.getValue()})");
//     if (!ok && throwOnFail) {
//       throw StateError("FFmpeg failed with code ${rc?.getValue()}");
//     }
//     return ok;
//   }

//   static Future<String?> exportVideo(
//     String input,
//     List<VideoSegment> keeps, {
//     void Function(String)? onLog,
//   }) async {
//     final validKeeps = keeps.where((k) => k.end > k.start).toList();
//     if (validKeeps.isEmpty) {
//       onLog?.call("No valid segments to export. Skipping.");
//       return null;
//     }

//     final tmpDir = await getTemporaryDirectory();
//     final date = DateTime.now().millisecondsSinceEpoch;
//     final work = Directory(p.join(tmpDir.path, "export_$date"));
//     await work.create(recursive: true);
//     String log = "";

//     final k = validKeeps.single;
//     final out = p.join(work.path, "trimmed.mp4");
//     final success = await _runFfmpeg([
//       "-y",
//       "-ss",
//       "${k.start.inMilliseconds / 1000}",
//       "-to",
//       "${k.end.inMilliseconds / 1000}",
//       "-i",
//       input,
//       "-c",
//       "copy",
//       out,
//     ], onLog: (s) => log += s);

//     if (!success) {
//       await _runFfmpeg(
//         [
//           "-y",
//           "-ss",
//           "${k.start.inMilliseconds / 1000}",
//           "-to",
//           "${k.end.inMilliseconds / 1000}",
//           "-i",
//           input,
//           "-c:v",
//           "libx264",
//           "-c:a",
//           "aac",
//           "-movflags",
//           "+faststart",
//           out,
//         ],
//         onLog: (s) => log += s,
//         throwOnFail: true,
//       );
//     }

//     return out;
//   }
// }

// /// -------------------- Video Editor Page --------------------
// class VideoEditorPage extends StatefulWidget {
//   final String videoPath;
//   const VideoEditorPage({super.key, required this.videoPath});

//   @override
//   State<VideoEditorPage> createState() => _VideoEditorPageState();
// }

// class _VideoEditorPageState extends State<VideoEditorPage> {
//   late VideoPlayerController _controller;
//   List<VideoSegment> segments = [];
//   Duration videoDuration = Duration.zero;

//   double startPercent = 0.0;
//   double endPercent = 1.0;
//   List<Image> thumbnails = [];

//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.file(File(widget.videoPath))
//       ..initialize().then((_) async {
//         videoDuration = _controller.value.duration;
//         segments = [
//           VideoSegment(start: Duration.zero, end: _controller.value.duration),
//         ];
//         setState(() {});
//         await generateThumbnails();
//       });
//   }

//   Future<void> generateThumbnails() async {
//     const thumbCount = 10;
//     final List<Image> tempThumbs = [];
//     for (int i = 0; i < thumbCount; i++) {
//       final t = (_controller.value.duration.inMilliseconds / thumbCount) * i;
//       final path = await VideoThumbnail.thumbnailFile(
//         video: widget.videoPath,
//         imageFormat: ImageFormat.PNG,
//         timeMs: t.toInt(),
//         maxWidth: (MediaQuery.of(context).size.width * 0.08).toInt(),
//         quality: 100,
//         maxHeight: 100,
//       );
//       if (path != null) tempThumbs.add(Image.file(File(path)));
//     }
//     thumbnails = tempThumbs;
//     setState(() {});
//   }

//   void _playSelectedRange() {
//     if (!_controller.value.isInitialized) return;
//     final start = Duration(
//       milliseconds: (videoDuration.inMilliseconds * startPercent).toInt(),
//     );
//     final end = Duration(
//       milliseconds: (videoDuration.inMilliseconds * endPercent).toInt(),
//     );
//     _controller.seekTo(start);
//     _controller.play();

//     _controller.addListener(() {
//       final pos = _controller.value.position;
//       if (pos >= end) {
//         _controller.seekTo(start);
//       }
//     });
//   }

//   Future<void> exportVideo() async {
//     final start = Duration(
//       milliseconds: (videoDuration.inMilliseconds * startPercent).toInt(),
//     );
//     final end = Duration(
//       milliseconds: (videoDuration.inMilliseconds * endPercent).toInt(),
//     );
//     segments = [VideoSegment(start: start, end: end)];

//     final outputPath = await FFmpegService.exportVideo(
//       widget.videoPath,
//       segments,
//       onLog: (s) => print(s),
//     );

//     if (outputPath != null) {
//       print(outputPath);
//       playTheEditedVideo(outputPath);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Exported: $outputPath')));
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Export failed')));
//     }
//   }

//   void playTheEditedVideo(String path) {
//     _controller.pause();
//     _controller.dispose();
//     _controller = VideoPlayerController.file(File(path))
//       ..initialize().then((_) {
//         setState(() {});
//         _controller.play();
//       });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   // ------------------ Cropper overlay builder ------------------
//   Widget buildThumbnailCropper(double width) {
//     final handleWidth = 20.0;

//     final startX = startPercent * width;
//     final endX = endPercent * width;

//     return Stack(
//       children: [
//         // Thumbnails
//         Row(
//           children: thumbnails
//               .map(
//                 (t) => Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 2.0),
//                   child: SizedBox(
//                     width: (MediaQuery.of(context).size.width * 0.076),

//                     height: double.infinity, // fit container height
//                     child: FittedBox(
//                       fit: BoxFit.contain, // fit to height, maintain aspect
//                       child: t,
//                     ),
//                   ),
//                 ),
//               )
//               .toList(),
//         ),
//         // Dark overlay outside selected range
//         Positioned.fill(
//           child: Row(
//             children: [
//               Container(width: startX, color: Colors.black.withOpacity(0.5)),
//               Expanded(child: Container()),
//               Container(
//                 width: width - endX,
//                 color: Colors.black.withOpacity(0.5),
//               ),
//             ],
//           ),
//         ),
//         // Start handle
//         Positioned(
//           left: startX - handleWidth / 2,
//           top: 0,
//           bottom: 0,
//           child: GestureDetector(
//             onHorizontalDragUpdate: (d) {
//               setState(() {
//                 startPercent = (startX + d.delta.dx) / width;
//                 if (startPercent < 0) startPercent = 0;
//                 if (startPercent > endPercent - 0.05)
//                   startPercent = endPercent - 0.05;
//               });
//               _playSelectedRange();
//             },
//             child: Container(width: handleWidth, color: Colors.blue),
//           ),
//         ),
//         // End handle
//         Positioned(
//           left: endX - handleWidth / 2,
//           top: 0,
//           bottom: 0,
//           child: GestureDetector(
//             onHorizontalDragUpdate: (d) {
//               setState(() {
//                 endPercent = (endX + d.delta.dx) / width;
//                 if (endPercent > 1) endPercent = 1;
//                 if (endPercent < startPercent + 0.05)
//                   endPercent = startPercent + 0.05;
//               });
//               _playSelectedRange();
//             },
//             child: Container(width: handleWidth, color: Colors.blue),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final viewportWidth = MediaQuery.of(context).size.width - 40;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Video Editor")),
//       body: Column(
//         children: [
//           if (_controller.value.isInitialized)
//             AspectRatio(
//               aspectRatio: _controller.value.aspectRatio,
//               child: VideoPlayer(_controller),
//             ),
//           const SizedBox(height: 10),
//           // ------------------ WhatsApp-style cropper ------------------
//           Container(
//             width: viewportWidth,
//             height: 40,
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey.shade300),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: buildThumbnailCropper(viewportWidth),
//           ),
//           const SizedBox(height: 10),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton(
//                 onPressed: () {
//                   if (_controller.value.isPlaying) {
//                     _controller.pause();
//                   } else {
//                     _playSelectedRange();
//                   }
//                   setState(() {});
//                 },
//                 child: Text(_controller.value.isPlaying ? 'Pause' : 'Play'),
//               ),
//               const SizedBox(width: 10),
//               ElevatedButton(
//                 onPressed: exportVideo,
//                 child: const Text('Export'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// -------------------- Home Page --------------------
// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   Future<void> pickVideo(BuildContext context) async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.video);

//     if (result != null && result.files.single.path != null) {
//       final path = result.files.single.path!;
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => VideoEditorPage(videoPath: path)),
//       );
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("No video selected")));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Home")),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () => pickVideo(context),
//           child: const Text("Pick Video"),
//         ),
//       ),
//     );
//   }
// }

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: HomePage(),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_video_editor/presentation/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
