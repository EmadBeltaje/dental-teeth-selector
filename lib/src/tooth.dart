import 'dart:ui';

/// A single selectable tooth parsed from the chart SVG.
class Tooth {
  /// Creates a tooth from one or more absolute SVG [paths].
  ///
  /// Multiple contours (outer crown + inner anatomy) are united so selection
  /// fill covers the full tooth.
  Tooth({required this.id, required List<Path> paths}) {
    assert(paths.isNotEmpty, 'Tooth requires at least one path');
    var combined = paths.first;
    for (var i = 1; i < paths.length; i++) {
      combined = Path.combine(PathOperation.union, combined, paths[i]);
    }
    rect = combined.getBounds();
    path = combined.shift(-rect.topLeft);
  }

  /// Internal tooth id in Universal Numbering System (`"1"` … `"32"`).
  ///
  /// Public selection ids may be remapped to European (FDI) by
  /// [DentalTeethSelector.numberingSystem].
  final String id;

  /// Tooth outline in local coordinates (origin at [rect.topLeft]).
  late final Path path;

  /// Bounding box of the tooth in SVG space.
  late final Rect rect;

  /// Whether this tooth is currently selected.
  bool selected = false;
}
