import 'package:flutter/material.dart';

class ThumbnailCropper extends StatelessWidget {
  final double startPercent;
  final double endPercent;
  final double width;
  final List<Image> thumbnails;
  final void Function(double) onStartChanged;
  final void Function(double) onEndChanged;

  const ThumbnailCropper({
    super.key,
    required this.startPercent,
    required this.endPercent,
    required this.width,
    required this.thumbnails,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  @override
  Widget build(BuildContext context) {
    const handleWidth = 20.0;
    final startX = startPercent * width;
    final endX = endPercent * width;

    return Stack(
      children: [
        Row(
          children: thumbnails
              .map(
                (t) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                  child: SizedBox(
                    width: width / thumbnails.length,
                    height: double.infinity,
                    child: FittedBox(fit: BoxFit.contain, child: t),
                  ),
                ),
              )
              .toList(),
        ),
        Positioned.fill(
          child: Row(
            children: [
              Container(width: startX, color: Colors.black.withOpacity(0.5)),
              Expanded(child: Container()),
              Container(
                  width: width - endX, color: Colors.black.withOpacity(0.5)),
            ],
          ),
        ),
        Positioned(
          left: startX, //- handleWidth / 2,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            onHorizontalDragUpdate: (d) =>
                onStartChanged((startX + d.delta.dx) / width),
            child: Container(width: handleWidth, color: Colors.blue),
          ),
        ),
        Positioned(
          left: endX, //- handleWidth / 2,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            onHorizontalDragUpdate: (d) =>
                onEndChanged((endX + d.delta.dx) / width),
            child: Container(width: handleWidth, color: Colors.blue),
          ),
        ),
      ],
    );
  }
}
