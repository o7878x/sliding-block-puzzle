// ignore_for_file: avoid_print
// tools/generate_icon.dart
//
// Generates a 1024×1024 app icon for the sliding-block puzzle.
// Run: dart run tools/generate_icon.dart
//
// The icon shows a solved 4×4 puzzle grid with purple-to-blue gradient tiles
// and the empty cell in the bottom-right corner.

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  const int size = 1024;
  final image = img.Image(width: size, height: size);

  // ── 1. Background (lavender radial gradient) ──────────────────────
  _fillBackground(image, size);

  // ── 2. Grid area ──────────────────────────────────────────────────
  const int gridSize = 4; // 4×4 puzzle
  const double gridFraction = 0.68;
  final int gridExtent = (size * gridFraction).round();
  final int cellExtent = gridExtent ~/ gridSize;
  final int gridLeft = (size - gridExtent) ~/ 2;
  final int gridTop = (size - gridExtent) ~/ 2 + 12;

  // Drop shadow behind the grid
  _drawGridShadow(image, gridLeft, gridTop, gridExtent, cellExtent);

  // ── 3. Draw each tile ──────────────────────────────────────────────
  for (int row = 0; row < gridSize; row++) {
    for (int col = 0; col < gridSize; col++) {
      final int tileNum = row * gridSize + col + 1;
      final bool isEmpty = tileNum == 16; // bottom-right is empty

      final int tx = gridLeft + col * cellExtent;
      final int ty = gridTop + row * cellExtent;
      final int pad = (cellExtent * 0.06).round().clamp(3, 14);
      final int rx = (cellExtent * 0.13).round().clamp(4, 24);

      if (isEmpty) {
        _drawEmptyTile(image, tx, ty, cellExtent, pad, rx);
      } else {
        _drawNumberedTile(
            image, tx, ty, cellExtent, pad, rx, row, col, gridSize, tileNum);
      }
    }
  }

  // ── 4. Save ──────────────────────────────────────────────────────
  final file = File('assets/app_icon.png');
  file.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
  print('✅ Icon generated: assets/app_icon.png  ($size×$size)');
}

// ── Background helpers ──────────────────────────────────────────────

void _fillBackground(img.Image image, int size) {
  const topLeftR = 245, topLeftG = 240, topLeftB = 255;   // #F5F0FF
  const botRightR = 232, botRightG = 234, botRightB = 246; // #E8EAF6
  final double cx = size / 2, cy = size / 2;
  final double maxDist = math.sqrt(cx * cx + cy * cy);

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final double dx = x - cx, dy = y - cy;
      final double dist = math.sqrt(dx * dx + dy * dy) / maxDist;
      final double t = dist; // 0 at center, 1 at corners

      final int r = (topLeftR + (botRightR - topLeftR) * t).round();
      final int g = (topLeftG + (botRightG - topLeftG) * t).round();
      final int b = (topLeftB + (botRightB - topLeftB) * t).round();
      image.setPixelRgb(x, y, r, g, b);
    }
  }
}

// ── Shadow ──────────────────────────────────────────────────────────

void _drawGridShadow(
    img.Image image, int left, int top, int extent, int cellExtent) {
  const int shadowOffset = 8;
  final int shadowRadius = (cellExtent * 0.20).round().clamp(6, 40);
  final int sx = left + shadowOffset;
  final int sy = top + shadowOffset;

  for (int y = sy - shadowRadius; y < sy + extent + shadowRadius; y++) {
    for (int x = sx - shadowRadius; x < sx + extent + shadowRadius; x++) {
      if (x < 0 || y < 0 || x >= image.width || y >= image.height) continue;

      final int dx = math.max(0, math.max(sx - x, x - (sx + extent)));
      final int dy = math.max(0, math.max(sy - y, y - (sy + extent)));
      final double dist = math.sqrt(dx * dx + dy * dy);
      if (dist > shadowRadius) continue;
      final double alpha = (1.0 - dist / shadowRadius) * 0.25;
      if (alpha <= 0) continue;

      final p = image.getPixel(x, y);
      final double dstR = p.r.toDouble();
      final double dstG = p.g.toDouble();
      final double dstB = p.b.toDouble();

      image.setPixelRgb(x, y,
          (dstR * (1 - alpha) + 60 * alpha).round().clamp(0, 255),
          (dstG * (1 - alpha) + 30 * alpha).round().clamp(0, 255),
          (dstB * (1 - alpha) + 90 * alpha).round().clamp(0, 255));
    }
  }
}

// ── Tile drawing ────────────────────────────────────────────────────

void _drawNumberedTile(img.Image image, int tx, int ty, int cellExtent,
    int pad, int rx, int row, int col, int gridSize, int tileNum) {
  // Gradient: purple #7C4DFF → blue #536DFE, varying by position
  final double t = (row + col) / (2.0 * (gridSize - 1));
  const purpleR = 124, purpleG = 77, purpleB = 255;
  const blueR = 83, blueG = 109, blueB = 254;
  final int r = (purpleR * (1 - t) + blueR * t).round();
  final int g = (purpleG * (1 - t) + blueG * t).round();
  final int b = (purpleB * (1 - t) + blueB * t).round();

  fillRoundedRect(image, tx + pad, ty + pad, tx + cellExtent - pad,
      ty + cellExtent - pad, rx, r, g, b);

  // Subtle highlight on top-left part of tile
  final int highlightBottom = ty + pad + (cellExtent - pad * 2) ~/ 3;
  fillRoundedRect(image, tx + pad, ty + pad, tx + cellExtent - pad,
      highlightBottom, rx,
      (r + 60).clamp(0, 255), (g + 60).clamp(0, 255), (b + 60).clamp(0, 255));

  // Number text
  final String label = '$tileNum';
  // Use arial_48 for larger, clearer text
  final font = img.arial48;
  img.drawString(image, label,
      font: font,
      color: img.ColorRgb8(255, 255, 255),
      x: tx + cellExtent ~/ 2,
      y: ty + cellExtent ~/ 2);
}

void _drawEmptyTile(
    img.Image image, int tx, int ty, int cellExtent, int pad, int rx) {
  final int x1 = tx + pad, y1 = ty + pad;
  final int x2 = tx + cellExtent - pad, y2 = ty + cellExtent - pad;
  // White fill
  fillRoundedRect(image, x1, y1, x2, y2, rx, 255, 255, 255);
  // Purple border (draw 3 concentric outlines)
  for (int w = 0; w < 3; w++) {
    outlineRoundedRect(
        image, x1 + w, y1 + w, x2 - w, y2 - w, (rx - w).clamp(1, rx), 124, 77, 255);
  }
}

// ── Shape primitives ────────────────────────────────────────────────

void fillRoundedRect(img.Image image, int x1, int y1, int x2, int y2, int r,
    int r8, int g8, int b8) {
  r = r.clamp(1, (x2 - x1) ~/ 2);
  if (r < 1) return;

  for (int y = y1; y < y2; y++) {
    for (int x = x1; x < x2; x++) {
      // Determine which corner we're in (if any)
      bool inCorner = false;
      int relX = 0, relY = 0;

      if (x < x1 + r && y < y1 + r) {
        relX = x - (x1 + r - 1);
        relY = y - (y1 + r - 1);
        inCorner = true;
      } else if (x >= x2 - r && y < y1 + r) {
        relX = x - (x2 - r);
        relY = y - (y1 + r - 1);
        inCorner = true;
      } else if (x < x1 + r && y >= y2 - r) {
        relX = x - (x1 + r - 1);
        relY = y - (y2 - r);
        inCorner = true;
      } else if (x >= x2 - r && y >= y2 - r) {
        relX = x - (x2 - r);
        relY = y - (y2 - r);
        inCorner = true;
      }

      if (inCorner) {
        if (relX * relX + relY * relY > r * r) continue;
      }

      image.setPixelRgb(x, y, r8, g8, b8);
    }
  }
}

void outlineRoundedRect(img.Image image, int x1, int y1, int x2, int y2,
    int r, int r8, int g8, int b8) {
  r = r.clamp(1, (x2 - x1) ~/ 2);

  for (int y = y1; y <= y2; y++) {
    for (int x = x1; x <= x2; x++) {
      if (x < 0 || y < 0 || x >= image.width || y >= image.height) continue;

      // Check if this pixel is on the boundary of the rounded rect
      final bool isLeft = x == x1;
      final bool isRight = x == x2;
      final bool isTop = y == y1;
      final bool isBottom = y == y2;

      // If not on any edge, skip
      if (!isLeft && !isRight && !isTop && !isBottom) continue;

      // For corner regions, the edge follows the arc, not the straight line
      bool skipCorner = false;
      if (isTop || isBottom) {
        if (x >= x1 && x < x1 + r) {
          final int cx = x1 + r - 1, cy = isTop ? y1 + r - 1 : y2 - r;
          final int dx = x - cx, dy = isTop ? y - cy : y - cy;
          if (dx * dx + dy * dy < r * r) skipCorner = true;
        } else if (x > x2 - r && x <= x2) {
          final int cx = x2 - r, cy = isTop ? y1 + r - 1 : y2 - r;
          final int dx = x - cx, dy = isTop ? y - cy : y - cy;
          if (dx * dx + dy * dy < r * r) skipCorner = true;
        }
      }
      if (isLeft || isRight) {
        if (y >= y1 && y < y1 + r) {
          final int cx = isLeft ? x1 + r - 1 : x2 - r, cy = y1 + r - 1;
          final int dx = x - cx, dy = y - cy;
          if (dx * dx + dy * dy < r * r) skipCorner = true;
        } else if (y > y2 - r && y <= y2) {
          final int cx = isLeft ? x1 + r - 1 : x2 - r, cy = y2 - r;
          final int dx = x - cx, dy = y - cy;
          if (dx * dx + dy * dy < r * r) skipCorner = true;
        }
      }

      if (skipCorner) continue;

      // Blend the border color with anti-aliasing
      final p = image.getPixel(x, y);
      final double dstR = p.r.toDouble();
      final double dstG = p.g.toDouble();
      final double dstB = p.b.toDouble();
      const double alpha = 0.35;

      image.setPixelRgb(x, y,
          (dstR * (1 - alpha) + r8 * alpha).round().clamp(0, 255),
          (dstG * (1 - alpha) + g8 * alpha).round().clamp(0, 255),
          (dstB * (1 - alpha) + b8 * alpha).round().clamp(0, 255));
    }
  }
}