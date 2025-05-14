import 'package:flutter/material.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:twenty_forty_eight/main.dart';

class Tile extends StatelessWidget {
  final String id;
  final int x, y, val;
  final double tileSize;

  const Tile({
    required this.id,
    required this.x,
    required this.y,
    required this.val,
    required this.tileSize,
    super.key,
  });

  Color tileColor(int val) {
    var code =
        val == 2
            ? 0xfffcff00
            : val == 4
            ? 0xffff8c00
            : val == 8
            ? 0xffff00ff
            : val == 16
            ? 0xffff007f
            : val == 32
            ? 0xff00f7ff
            : val == 64
            ? 0xff00ced1
            : val == 128
            ? 0xff00a4ff
            : val == 256
            ? 0xffff6eb4
            : val == 512
            ? 0xff00fa9a
            : val == 1024
            ? 0xff00ff7f
            : 0xff39FF14;
    return Color(code);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tileSize,
      height: tileSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tileColor(val),
        borderRadius: BorderRadius.circular(br),
      ),
      child: Text(
        val.toString(),
        style: TextStyle(
          fontFamily: font,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
      ),
    );
  }
}

class TileData {
  final String id;
  int x, y, val;
  bool merged = false;
  Map<SwipeDirection, int> freeSpace = <SwipeDirection, int>{};

  TileData(this.id, this.x, this.y, this.val);
}

double posCalc(int i, double tileSize) {
  return i * (tileSize + bp);
}
