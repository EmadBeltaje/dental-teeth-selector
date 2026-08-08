import 'package:flutter/material.dart';

import 'teeth_chart_data.dart';
import 'tooth.dart';

/// Callback invoked whenever the set of selected teeth changes.
typedef TeethSelectionChanged = void Function(List<String> selectedTeeth);

/// Interactive Universal Numbering System dental chart.
///
/// Renders the bundled teeth SVG and lets users tap teeth to select them.
///
/// Example:
/// ```dart
/// DentalTeethSelector(
///   initiallySelected: const ['3', '14'],
///   selectedColor: Colors.teal,
///   toothColor: Colors.black87,
///   numberColor: Colors.black87,
///   rightLabel: 'Right',
///   leftLabel: 'Left',
///   labelColor: Colors.black54,
///   width: 320,
///   height: 480,
///   onSelected: (teeth) => debugPrint('$teeth'),
/// )
/// ```
class DentalTeethSelector extends StatefulWidget {
  /// Creates an interactive teeth selector.
  const DentalTeethSelector({
    super.key,
    required this.onSelected,
    this.initiallySelected = const [],
    this.selectedColor = const Color(0xFF4FC3F7),
    this.toothColor = Colors.black,
    this.numberColor = Colors.black,
    this.rightLabel = 'Right',
    this.leftLabel = 'Left',
    this.labelColor = Colors.black,
    this.width,
    this.height,
    this.multiSelect = true,
  });

  /// Called with the current selected tooth ids whenever selection changes.
  ///
  /// Ids use the Universal Numbering System (`"1"` … `"32"`).
  final TeethSelectionChanged onSelected;

  /// Tooth ids that start selected.
  final List<String> initiallySelected;

  /// Fill color for selected teeth.
  final Color selectedColor;

  /// Stroke color for tooth outlines in the SVG.
  final Color toothColor;

  /// Fill color for the tooth numbers drawn in the SVG.
  final Color numberColor;

  /// Label shown between teeth 1 and 32 (patient's right side).
  ///
  /// Defaults to `"Right"`.
  final String rightLabel;

  /// Label shown between teeth 16 and 17 (patient's left side).
  ///
  /// Defaults to `"Left"`.
  final String leftLabel;

  /// Color for [rightLabel] and [leftLabel].
  final Color labelColor;

  /// Optional width of the chart. When null, expands to parent constraints.
  final double? width;

  /// Optional height of the chart. When null, expands to parent constraints.
  final double? height;

  /// Whether more than one tooth can be selected at a time.
  final bool multiSelect;

  @override
  State<DentalTeethSelector> createState() => _DentalTeethSelectorState();
}

class _DentalTeethSelectorState extends State<DentalTeethSelector> {
  late final TeethChartData _data = _load();

  TeethChartData _load() {
    final data = loadTeethChartData();
    for (final id in widget.initiallySelected) {
      final tooth = data.teeth[id];
      if (tooth != null) {
        tooth.selected = true;
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox.fromSize(
          size: _data.size,
          child: _TeethChartView(
            data: _data,
            selectedColor: widget.selectedColor,
            toothColor: widget.toothColor,
            numberColor: widget.numberColor,
            rightLabel: widget.rightLabel,
            leftLabel: widget.leftLabel,
            labelColor: widget.labelColor,
            multiSelect: widget.multiSelect,
            onSelected: widget.onSelected,
            onChanged: () => setState(() {}),
          ),
        ),
      ),
    );
  }
}

class _TeethChartView extends StatelessWidget {
  const _TeethChartView({
    required this.data,
    required this.selectedColor,
    required this.toothColor,
    required this.numberColor,
    required this.rightLabel,
    required this.leftLabel,
    required this.labelColor,
    required this.multiSelect,
    required this.onSelected,
    required this.onChanged,
  });

  final TeethChartData data;
  final Color selectedColor;
  final Color toothColor;
  final Color numberColor;
  final String rightLabel;
  final String leftLabel;
  final Color labelColor;
  final bool multiSelect;
  final TeethSelectionChanged onSelected;
  final VoidCallback onChanged;

  List<String> get _selectedIds => data.teeth.entries
      .where((e) => e.value.selected)
      .map((e) => e.key)
      .toList(growable: false);

  void _toggle(Tooth tooth) {
    if (multiSelect) {
      tooth.selected = !tooth.selected;
    } else {
      final wasSelected = tooth.selected;
      for (final other in data.teeth.values) {
        other.selected = false;
      }
      tooth.selected = !wasSelected;
    }
    onChanged();
    onSelected(_selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    const labelBoxWidth = 700.0;
    const labelBoxHeight = 280.0;

    return SizedBox.fromSize(
      size: data.size,
      child: Stack(
        children: [
          for (final tooth in data.teeth.values)
            Positioned.fromRect(
              rect: tooth.rect,
              child: GestureDetector(
                onTap: () => _toggle(tooth),
                child: CustomPaint(
                  size: tooth.rect.size,
                  painter: _ToothFillPainter(
                    path: tooth.path,
                    color: tooth.selected ? selectedColor : Colors.transparent,
                  ),
                ),
              ),
            ),
          IgnorePointer(
            child: CustomPaint(
              size: data.size,
              painter: _StrokesPainter(
                paths: data.strokePaths,
                color: toothColor,
              ),
            ),
          ),
          IgnorePointer(
            child: CustomPaint(
              size: data.size,
              painter: _NumbersPainter(
                paths: data.numberPaths,
                color: numberColor,
              ),
            ),
          ),
          if (rightLabel.isNotEmpty)
            Positioned(
              left: data.rightLabelAnchor.dx - labelBoxWidth / 2,
              top: data.rightLabelAnchor.dy - labelBoxHeight / 2,
              width: labelBoxWidth,
              height: labelBoxHeight,
              child: IgnorePointer(
                child: Center(
                  child: Text(
                    rightLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 180,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          if (leftLabel.isNotEmpty)
            Positioned(
              left: data.leftLabelAnchor.dx - labelBoxWidth / 2,
              top: data.leftLabelAnchor.dy - labelBoxHeight / 2,
              width: labelBoxWidth,
              height: labelBoxHeight,
              child: IgnorePointer(
                child: Center(
                  child: Text(
                    leftLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 180,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StrokesPainter extends CustomPainter {
  _StrokesPainter({required this.paths, required this.color});

  final List<Path> paths;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokesPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.paths != paths;
  }
}

class _ToothFillPainter extends CustomPainter {
  _ToothFillPainter({required this.path, required this.color});

  final Path path;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) {
      return;
    }
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool? hitTest(Offset position) => path.contains(position);

  @override
  bool shouldRepaint(covariant _ToothFillPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.path != path;
  }
}

class _NumbersPainter extends CustomPainter {
  _NumbersPainter({required this.paths, required this.color});

  final List<Path> paths;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NumbersPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.paths != paths;
  }
}
