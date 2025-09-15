import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_video_editor/presentation/video_editor.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> pickVideo(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => VideoEditorPage(videoPath: path)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No video selected")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => pickVideo(context),
          child: const Text("Pick Video"),
        ),
      ),
    );
  }
}
