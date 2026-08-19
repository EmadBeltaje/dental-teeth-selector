import 'package:flutter/material.dart';

import 'numbering_system.dart';
import 'teeth_chart_data.dart';
import 'tooth.dart';

export 'numbering_system.dart';

/// Callback invoked whenever the set of selected teeth changes.
typedef TeethSelectionChanged = void Function(List<String> selectedTeeth);

/// Callback invoked whenever the set of fallen (missing) teeth changes.
typedef FallenTeethChanged = void Function(List<String> fallenTeeth);

/// Interactive dental chart with Universal or European (FDI) numbering.
///
/// Renders the bundled teeth SVG and lets users tap teeth to select them.
/// Tooth ids in [onSelected] / [initiallySelected] / [fallenTeeth] match
/// [numberingSystem].
///
/// Example:
/// ```dart
/// DentalTeethSelector(
///   numberingSystem: TeethNumberingSystem.european,
///   initiallySelected: const ['11', '21'],
///   showFallenTeeth: true,
///   fallenTeeth: const ['18', '28'],
///   selectedColor: Colors.teal,
///   toothColor: Colors.black87,
///   numberColor: Colors.black87,
///   rightLabel: 'Right',
///   leftLabel: 'Left',
///   labelColor: Colors.black54,
///   width: 320,
///   height: 480,
///   onSelected: (teeth) => debugPrint('$teeth'),
///   onFallenChanged: (fallen) => debugPrint('fallen: $fallen'),
/// )
/// ```
class DentalTeethSelector extends StatefulWidget {
  /// Creates an interactive teeth selector.
  DentalTeethSelector({
    super.key,
    required this.onSelected,
    this.numberingSystem = TeethNumberingSystem.universal,
    this.initiallySelected = const [],
    this.showFallenTeeth = false,
    this.fallenTeeth = const [],
    this.selectingFallenTeeth = false,
    this.onFallenChanged,
    this.selectedColor = const Color(0xFF4FC3F7),
    this.fallenColor = const Color(0xFFE53935),
    this.toothColor = Colors.black,
    this.numberColor = Colors.black,
    this.rightLabel = 'Right',
    this.leftLabel = 'Left',
    this.labelColor = Colors.black,
    this.width,
    this.height,
    this.multiSelect = true,
  }) : assert(
         fallenTeeth.isEmpty || showFallenTeeth,
         'fallenTeeth requires showFallenTeeth: true',
       ),
       assert(
         !selectingFallenTeeth || showFallenTeeth,
         'selectingFallenTeeth requires showFallenTeeth: true',
       ),
       assert(
         initiallySelected.toSet().intersection(fallenTeeth.toSet()).isEmpty,
         'fallenTeeth ids must not appear in initiallySelected',
       );

  /// Numbering system for displayed labels and selection ids.
  ///
  /// Defaults to [TeethNumberingSystem.universal].
  final TeethNumberingSystem numberingSystem;

  /// Called with the current selected tooth ids whenever selection changes.
  ///
  /// Ids match [numberingSystem]: Universal `"1"`…`"32"`, or European FDI
  /// two-digit ids such as `"11"`, `"18"`, `"21"`, `"28"`, `"31"`, `"38"`,
  /// `"41"`, `"48"`.
  final TeethSelectionChanged onSelected;

  /// Tooth ids that start selected (interpreted with [numberingSystem]).
  ///
  /// Must not overlap [fallenTeeth].
  final List<String> initiallySelected;

  /// Whether fallen (missing) teeth are shown and enforced.
  ///
  /// When `false`, [fallenTeeth] must be empty.
  final bool showFallenTeeth;

  /// Tooth ids marked as fallen / missing (interpreted with [numberingSystem]).
  ///
  /// Requires [showFallenTeeth]. Must not overlap [initiallySelected].
  /// Fallen teeth are painted with [fallenColor] and cannot be selected
  /// while [selectingFallenTeeth] is `false`.
  final List<String> fallenTeeth;

  /// When `true` (and [showFallenTeeth] is enabled), taps toggle fallen
  /// teeth instead of normal selection.
  ///
  /// Use a parent Switch / SegmentedButton to let the user choose mode.
  final bool selectingFallenTeeth;

  /// Called when the fallen set changes (only while marking fallen teeth).
  final FallenTeethChanged? onFallenChanged;

  /// Fill color for selected teeth.
  final Color selectedColor;

  /// Fill color for fallen teeth.
  ///
  /// Defaults to red.
  final Color fallenColor;

  /// Stroke color for tooth outlines in the SVG.
  final Color toothColor;

  /// Fill color for the tooth numbers drawn in the SVG / as text.
  final Color numberColor;

  /// Label shown on the patient's right side
  /// (Universal teeth 1 & 32 / European 18 & 48).
  ///
  /// Defaults to `"Right"`.
  final String rightLabel;

  /// Label shown on the patient's left side
  /// (Universal teeth 16 & 17 / European 28 & 38).
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
  ///
  /// Does not apply while [selectingFallenTeeth] is `true`.
  final bool multiSelect;

  @override
  State<DentalTeethSelector> createState() => _DentalTeethSelectorState();
}

class _DentalTeethSelectorState extends State<DentalTeethSelector> {
  late final TeethChartData _data = _loadChart();
  late Set<String> _fallenUniversal;

  TeethChartData _loadChart() {
    final data = loadTeethChartData();
    for (final rawId in widget.initiallySelected) {
      final universalId = convertToothId(
        rawId,
        from: widget.numberingSystem,
        to: TeethNumberingSystem.universal,
      );
      final tooth = data.teeth[universalId];
      if (tooth != null) {
        tooth.selected = true;
      }
    }
    return data;
  }

  Set<String> _fallenFromWidget() {
    if (!widget.showFallenTeeth) {
      return <String>{};
    }
    return convertToothIds(
      widget.fallenTeeth,
      from: widget.numberingSystem,
      to: TeethNumberingSystem.universal,
    ).toSet();
  }

  @override
  void initState() {
    super.initState();
    _fallenUniversal = _fallenFromWidget();
  }

  @override
  void didUpdateWidget(covariant DentalTeethSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fallenTeeth != widget.fallenTeeth ||
        oldWidget.showFallenTeeth != widget.showFallenTeeth ||
        oldWidget.numberingSystem != widget.numberingSystem) {
      _fallenUniversal = _fallenFromWidget();
      // Drop selection on any tooth that is now fallen.
      for (final id in _fallenUniversal) {
        final tooth = _data.teeth[id];
        if (tooth != null) {
          tooth.selected = false;
        }
      }
    }
  }

  List<String> get _selectedIds {
    final universal = _data.teeth.entries
        .where((e) => e.value.selected && !_fallenUniversal.contains(e.key))
        .map((e) => e.key);
    return convertToothIds(
      universal,
      from: TeethNumberingSystem.universal,
      to: widget.numberingSystem,
    );
  }

  List<String> get _fallenIds {
    return convertToothIds(
      _fallenUniversal,
      from: TeethNumberingSystem.universal,
      to: widget.numberingSystem,
    );
  }

  void _toggleFallen(Tooth tooth) {
    final id = tooth.id;
    // Already selected → ignore (cannot mark selected teeth as fallen).
    if (!_fallenUniversal.contains(id) && tooth.selected) {
      return;
    }
    setState(() {
      if (_fallenUniversal.contains(id)) {
        _fallenUniversal.remove(id);
      } else {
        _fallenUniversal.add(id);
      }
    });
    widget.onFallenChanged?.call(_fallenIds);
  }

  void _toggleSelected(Tooth tooth) {
    if (_fallenUniversal.contains(tooth.id)) {
      return;
    }
    if (widget.multiSelect) {
      tooth.selected = !tooth.selected;
    } else {
      final wasSelected = tooth.selected;
      for (final other in _data.teeth.values) {
        other.selected = false;
      }
      tooth.selected = !wasSelected;
    }
    setState(() {});
    widget.onSelected(_selectedIds);
  }

  void _onToothTap(Tooth tooth) {
    if (widget.showFallenTeeth && widget.selectingFallenTeeth) {
      _toggleFallen(tooth);
    } else {
      _toggleSelected(tooth);
    }
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
            numberingSystem: widget.numberingSystem,
            fallenUniversal: _fallenUniversal,
            selectedColor: widget.selectedColor,
            fallenColor: widget.fallenColor,
            toothColor: widget.toothColor,
            numberColor: widget.numberColor,
            rightLabel: widget.rightLabel,
            leftLabel: widget.leftLabel,
            labelColor: widget.labelColor,
            onToothTap: _onToothTap,
          ),
        ),
      ),
    );
  }
}

class _TeethChartView extends StatelessWidget {
  const _TeethChartView({
    required this.data,
    required this.numberingSystem,
    required this.fallenUniversal,
    required this.selectedColor,
    required this.fallenColor,
    required this.toothColor,
    required this.numberColor,
    required this.rightLabel,
    required this.leftLabel,
    required this.labelColor,
    required this.onToothTap,
  });

  final TeethChartData data;
  final TeethNumberingSystem numberingSystem;
  final Set<String> fallenUniversal;
  final Color selectedColor;
  final Color fallenColor;
  final Color toothColor;
  final Color numberColor;
  final String rightLabel;
  final String leftLabel;
  final Color labelColor;
  final void Function(Tooth tooth) onToothTap;

  Color _fillFor(Tooth tooth) {
    if (fallenUniversal.contains(tooth.id)) {
      return fallenColor;
    }
    if (tooth.selected) {
      return selectedColor;
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    const labelBoxWidth = 700.0;
    const labelBoxHeight = 280.0;
    final useSvgNumbers = numberingSystem == TeethNumberingSystem.universal;

    return SizedBox.fromSize(
      size: data.size,
      child: Stack(
        children: [
          for (final tooth in data.teeth.values)
            Positioned.fromRect(
              rect: tooth.rect,
              child: GestureDetector(
                onTap: () => onToothTap(tooth),
                child: CustomPaint(
                  size: tooth.rect.size,
                  painter: _ToothFillPainter(
                    path: tooth.path,
                    color: _fillFor(tooth),
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
          if (useSvgNumbers)
            IgnorePointer(
              child: CustomPaint(
                size: data.size,
                painter: _NumbersPainter(
                  paths: data.numberPaths,
                  color: numberColor,
                ),
              ),
            )
          else
            for (final entry in data.numberCenters.entries)
              Positioned(
                left: entry.value.dx - 200,
                top: entry.value.dy - data.numberFontSize,
                width: 400,
                height: data.numberFontSize * 2,
                child: IgnorePointer(
                  child: Center(
                    child: Text(
                      convertToothId(
                        entry.key,
                        from: TeethNumberingSystem.universal,
                        to: numberingSystem,
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: numberColor,
                        fontSize: data.numberFontSize,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
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
