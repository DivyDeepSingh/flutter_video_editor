import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/video_segment.dart';

class FFmpegService {
  static Future<bool> _runFfmpeg(
    List<String> args, {
    void Function(String)? onLog,
    bool throwOnFail = false,
  }) async {
    final cmd = args.map((s) => s.contains(' ') ? '"$s"' : s).join(' ');
    onLog?.call("\n\n\$ ffmpeg $cmd\n");
    final session = await FFmpegKit.execute(args.join(' '));
    final rc = await session.getReturnCode();
    final logs = await session.getOutput();
    if (logs?.isNotEmpty == true) onLog?.call(logs!);
    final ok = ReturnCode.isSuccess(rc);
    onLog?.call("=> ${ok ? 'OK' : 'FAILED'} (code: ${rc?.getValue()})");
    if (!ok && throwOnFail) {
      throw StateError("FFmpeg failed with code ${rc?.getValue()}");
    }
    return ok;
  }

  static Future<String?> exportVideo(
    String input,
    List<VideoSegment> keeps, {
    void Function(String)? onLog,
  }) async {
    final validKeeps = keeps.where((k) => k.end > k.start).toList();
    if (validKeeps.isEmpty) {
      onLog?.call("No valid segments to export. Skipping.");
      return null;
    }

    final tmpDir = await getTemporaryDirectory();
    final date = DateTime.now().millisecondsSinceEpoch;
    final work = Directory(p.join(tmpDir.path, "export_$date"));
    await work.create(recursive: true);

    final k = validKeeps.single;
    final out = p.join(work.path, "trimmed.mp4");
    final success = await _runFfmpeg([
      "-y",
      "-ss",
      "${k.start.inMilliseconds / 1000}",
      "-to",
      "${k.end.inMilliseconds / 1000}",
      "-i",
      input,
      "-c",
      "copy",
      out,
    ], onLog: onLog);

    if (!success) {
      await _runFfmpeg(
        [
          "-y",
          "-ss",
          "${k.start.inMilliseconds / 1000}",
          "-to",
          "${k.end.inMilliseconds / 1000}",
          "-i",
          input,
          "-c:v",
          "libx264",
          "-c:a",
          "aac",
          "-movflags",
          "+faststart",
          out,
        ],
        onLog: onLog,
        throwOnFail: true,
      );
    }

    return out;
  }
}
