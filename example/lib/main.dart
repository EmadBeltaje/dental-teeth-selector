import 'package:dental_teeth_selector/dental_teeth_selector.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

enum _DemoTab { universal, european, fallen }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Dental Teeth Selector')),
        body: const _DemoPage(),
      ),
    );
  }
}

class _DemoPage extends StatefulWidget {
  const _DemoPage();

  @override
  State<_DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<_DemoPage> {
  _DemoTab _tab = _DemoTab.universal;

  /// Always stored in the active numbering system for Universal / European tabs.
  List<String> _selected = const ['1', '2', '3', '14', '15', '16'];

  /// Always Universal ids — fallen demo uses Universal numbering.
  List<String> _fallen = const ['8', '9'];

  bool _selectingFallen = false;

  TeethNumberingSystem get _system => switch (_tab) {
    _DemoTab.universal || _DemoTab.fallen => TeethNumberingSystem.universal,
    _DemoTab.european => TeethNumberingSystem.european,
  };

  void _setTab(_DemoTab tab) {
    if (tab == _tab) {
      return;
    }
    setState(() {
      final oldSystem = _system;
      _tab = tab;
      final newSystem = _system;

      if (oldSystem != newSystem) {
        _selected = convertToothIds(_selected, from: oldSystem, to: newSystem);
      }

      if (tab == _DemoTab.fallen) {
        // Selection and fallen must not overlap.
        _selected = _selected.where((id) => !_fallen.contains(id)).toList();
        _selectingFallen = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFallenTab = _tab == _DemoTab.fallen;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SegmentedButton<_DemoTab>(
            segments: const [
              ButtonSegment(
                value: _DemoTab.universal,
                label: Text('Universal'),
              ),
              ButtonSegment(value: _DemoTab.european, label: Text('European')),
              ButtonSegment(
                value: _DemoTab.fallen,
                label: Text('Fallen teeth'),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (next) => _setTab(next.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _selected.isEmpty
                    ? 'No teeth selected'
                    : 'Selected: ${_selected.join(', ')}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (isFallenTab) ...[
                const SizedBox(height: 4),
                Text(
                  _fallen.isEmpty
                      ? 'No fallen teeth'
                      : 'Fallen: ${_fallen.join(', ')}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFE53935),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isFallenTab)
          SwitchListTile(
            title: const Text('Mark fallen teeth'),
            subtitle: Text(
              _selectingFallen
                  ? 'Tap teeth to mark / unmark as fallen (red)'
                  : 'Tap teeth for normal selection (fallen stay red)',
            ),
            value: _selectingFallen,
            onChanged: (v) => setState(() => _selectingFallen = v),
          ),
        Expanded(
          child: Center(
            child: DentalTeethSelector(
              key: ValueKey(_tab),
              numberingSystem: _system,
              width: 320,
              height: 460,
              initiallySelected: _selected,
              showFallenTeeth: isFallenTab,
              fallenTeeth: isFallenTab ? _fallen : const [],
              selectingFallenTeeth: isFallenTab && _selectingFallen,
              selectedColor: const Color(0xFF4FC3F7),
              fallenColor: const Color(0xFFE53935),
              toothColor: const Color(0xFF1A1A1A),
              numberColor: const Color(0xFF1A1A1A),
              rightLabel: 'Right',
              leftLabel: 'Left',
              labelColor: const Color(0xFF1A1A1A),
              onSelected: (teeth) => setState(() => _selected = teeth),
              onFallenChanged: (fallen) => setState(() => _fallen = fallen),
            ),
          ),
        ),
      ],
    );
  }
}
