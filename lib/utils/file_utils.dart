import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileUtils {
  static Future<String> getTempFilePath(String name) async {
    final dir = await getTemporaryDirectory();
    return p.join(dir.path, name);
  }

  static Future<void> deleteFile(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }
}
