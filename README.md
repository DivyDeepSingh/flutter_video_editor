# Flutter Video Editor (Android + iOS)

A minimal Flutter app that lets you:
- Import a video
- Split on a thumbnail timeline and mark segments for deletion (tap to toggle red = delete)
- Preview playback that *skips deleted ranges*
- Export to MP4
  - Single segment: tries `-c copy` (stream copy, very fast). If it fails (non-keyframe boundaries), falls back to re-encode (x264 + AAC).
  - Multi segment: exports per-segment (copy with fallback), then tries concat demuxer (`-f concat -c copy`). If that fails, falls back to concat filter (re-encodes).

## How to run

1. Ensure Flutter SDK is installed and set up for Android/iOS.
2. Extract this project and `cd` into it.
3. Run:
   ```bash
   flutter pub get
   flutter run
   ```

### Notes

- Uses these packages:
  - `file_picker` for choosing a video file
  - `video_player` for preview
  - `video_thumbnail` to generate the thumbnail strip
  - `ffmpeg_kit_flutter_full_gpl` for export
- Timeline:
  - Long-press on the timeline to *seek*.
  - Tap on a region to toggle deletion (red overlay = will be removed).
  - Use the scissor icon to add a split at the current playhead.
- Exported file path is shown at the bottom after export completes.

### iOS

- You may need to open the iOS project in Xcode once (`open ios/Runner.xcworkspace`) to set a valid signing team.
- The app writes exported files to a temporary app directory; you can share or move them from there.

### Android

- Targets SDK 34, min SDK 24.

### Caveats

- FFmpeg stream copy only works if your cut points land on keyframes. We automatically fall back to re-encode when needed.
- The concat demuxer requires matching codecs/parameters; if any segment was re-encoded, we fall back to concat filter (re-encodes the final output).
- This sample is intentionally simple (no background isolate, no precise frame scrubbing).

### License

Sample code is MIT. FFmpeg binaries are provided by `ffmpeg_kit_flutter_full_gpl` (GPL), which may affect how you distribute your app.
