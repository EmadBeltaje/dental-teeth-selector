import 'package:flutter/painting.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

import 'teeth_svg.dart';
import 'tooth.dart';

/// Extra vertical space inserted between the upper and lower jaws.
const double kJawGap = 520;

/// Parsed dental chart geometry from the bundled SVG string.
class TeethChartData {
  /// Creates chart data from already-parsed geometry.
  TeethChartData({
    required this.size,
    required this.teeth,
    required this.strokePaths,
    required this.numberPaths,
    required this.rightLabelAnchor,
    required this.leftLabelAnchor,
  });

  /// Native SVG canvas size (includes [kJawGap] between jaws).
  final Size size;

  /// Selectable teeth keyed by Universal Numbering System id.
  final Map<String, Tooth> teeth;

  /// Non-selectable outline / anatomy strokes (SVG space).
  final List<Path> strokePaths;

  /// Number glyph paths (SVG space).
  final List<Path> numberPaths;

  /// Center of the "Right" label (between teeth 1 and 32).
  final Offset rightLabelAnchor;

  /// Center of the "Left" label (between teeth 16 and 17).
  final Offset leftLabelAnchor;
}

/// Loads and indexes the bundled Universal Numbering System teeth SVG.
TeethChartData loadTeethChartData() => parseTeethChartData(kTeethSvg);

/// Parses [svg] into selectable teeth, strokes, and number glyphs.
///
/// Every closed contour is assigned to the nearest number label (`1`–`32`).
/// Contours for the same tooth are united so selection fill covers the full
/// crown. Lower-jaw geometry is shifted down by [kJawGap] so side labels fit
/// between the arches.
TeethChartData parseTeethChartData(String svg) {
  final doc = XmlDocument.parse(svg);
  final root = doc.rootElement;

  final width = double.parse(root.getAttribute('width')!);
  final height = double.parse(root.getAttribute('height')!);

  final closed = <_ClosedPath>[];
  final rawStrokes = <Path>[];

  for (final element in root.childElements) {
    if (element.name.local != 'path') {
      continue;
    }
    final d = element.getAttribute('d');
    if (d == null || d.isEmpty) {
      continue;
    }
    final path = parseSvgPathData(d);
    final isClosed = d.trim().toLowerCase().endsWith('z');
    if (isClosed) {
      closed.add(_ClosedPath(id: element.getAttribute('id') ?? '', path: path));
    } else {
      rawStrokes.add(path);
    }
  }

  final numberCenters = <_NumberLabel>[];
  final rawNumberPaths = <Path>[];

  for (final element in root.childElements) {
    if (element.name.local != 'g') {
      continue;
    }
    final id = element.getAttribute('id') ?? '';
    if (!id.startsWith('text')) {
      continue;
    }

    final offset = _parseTranslate(element.getAttribute('transform'));
    var cx = 0.0;
    var cy = 0.0;
    var count = 0;

    for (final child in element.childElements) {
      if (child.name.local != 'path') {
        continue;
      }
      final d = child.getAttribute('d');
      if (d == null || d.isEmpty) {
        continue;
      }
      final local = parseSvgPathData(d);
      final shifted = local.shift(offset);
      rawNumberPaths.add(shifted);
      final bounds = shifted.getBounds();
      cx += bounds.center.dx;
      cy += bounds.center.dy;
      count++;
    }

    if (count == 0) {
      continue;
    }
    numberCenters.add(
      _NumberLabel(
        id: '${numberCenters.length + 1}',
        center: Offset(cx / count, cy / count),
      ),
    );
  }

  // 1) Guarantee every number gets its nearest unused closed contour.
  final pathsByTooth = <String, List<Path>>{
    for (final label in numberCenters) label.id: <Path>[],
  };
  final usedClosedIds = <String>{};

  for (final label in numberCenters) {
    _ClosedPath? best;
    var bestDist = double.infinity;
    for (final candidate in closed) {
      if (usedClosedIds.contains(candidate.id)) {
        continue;
      }
      final center = candidate.path.getBounds().center;
      final dx = center.dx - label.center.dx;
      final dy = center.dy - label.center.dy;
      final dist = dx * dx + dy * dy;
      if (dist < bestDist) {
        bestDist = dist;
        best = candidate;
      }
    }
    if (best == null) {
      continue;
    }
    usedClosedIds.add(best.id);
    pathsByTooth[label.id]!.add(best.path);
  }

  // 2) Attach leftover closed contours to the nearest tooth.
  for (final candidate in closed) {
    if (usedClosedIds.contains(candidate.id)) {
      continue;
    }
    String? bestId;
    var bestDist = double.infinity;
    final center = candidate.path.getBounds().center;
    for (final label in numberCenters) {
      final dx = center.dx - label.center.dx;
      final dy = center.dy - label.center.dy;
      final dist = dx * dx + dy * dy;
      if (dist < bestDist) {
        bestDist = dist;
        bestId = label.id;
      }
    }
    if (bestId != null) {
      pathsByTooth[bestId]!.add(candidate.path);
    }
  }

  // Build unshifted teeth so we can measure the natural jaw midline.
  final unshifted = <String, Tooth>{};
  for (final entry in pathsByTooth.entries) {
    if (entry.value.isEmpty) {
      continue;
    }
    unshifted[entry.key] = Tooth(id: entry.key, paths: entry.value);
  }

  final upperBottom = unshifted['1']!.rect.bottom;
  final lowerTop = unshifted['32']!.rect.top;
  final midY = (upperBottom + lowerTop) / 2;
  final lowerShift = Offset(0, kJawGap);

  Path shiftLowerIfNeeded(Path path) {
    if (path.getBounds().center.dy > midY) {
      return path.shift(lowerShift);
    }
    return path;
  }

  // Rebuild teeth with lower jaw pushed down to open a label gap.
  final teeth = <String, Tooth>{};
  for (final entry in pathsByTooth.entries) {
    if (entry.value.isEmpty) {
      continue;
    }
    final idNum = int.parse(entry.key);
    final paths = idNum >= 17
        ? entry.value.map((p) => p.shift(lowerShift)).toList(growable: false)
        : entry.value;
    teeth[entry.key] = Tooth(id: entry.key, paths: paths);
  }

  final strokes = <Path>[
    for (final path in rawStrokes) shiftLowerIfNeeded(path),
    for (final tooth in teeth.values) tooth.path.shift(tooth.rect.topLeft),
  ];

  final numberPaths = <Path>[
    for (final path in rawNumberPaths) shiftLowerIfNeeded(path),
  ];

  final gapCenterY = midY + kJawGap / 2;
  final rightLabelAnchor = Offset(teeth['1']!.rect.center.dx, gapCenterY);
  final leftLabelAnchor = Offset(teeth['16']!.rect.center.dx, gapCenterY);

  return TeethChartData(
    size: Size(width, height + kJawGap),
    teeth: teeth,
    strokePaths: strokes,
    numberPaths: numberPaths,
    rightLabelAnchor: rightLabelAnchor,
    leftLabelAnchor: leftLabelAnchor,
  );
}

class _ClosedPath {
  const _ClosedPath({required this.id, required this.path});

  final String id;
  final Path path;
}

class _NumberLabel {
  const _NumberLabel({required this.id, required this.center});

  final String id;
  final Offset center;
}

Offset _parseTranslate(String? transform) {
  if (transform == null || transform.isEmpty) {
    return Offset.zero;
  }
  final match = RegExp(
    r'translate\(\s*([^,\s]+)\s*,\s*([^)\s]+)\s*\)',
  ).firstMatch(transform);
  if (match == null) {
    return Offset.zero;
  }
  return Offset(double.parse(match.group(1)!), double.parse(match.group(2)!));
}
