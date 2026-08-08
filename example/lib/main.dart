import 'package:dental_teeth_selector/dental_teeth_selector.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

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
  List<String> _selected = const ['1', '2', '3', '14', '15', '16'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _selected.isEmpty
                ? 'No teeth selected'
                : 'Selected: ${_selected.join(', ')}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: Center(
            child: DentalTeethSelector(
              width: 320,
              height: 460,
              initiallySelected: const ['1', '2', '3', '14', '15', '16'],
              selectedColor: const Color(0xFF4FC3F7),
              toothColor: const Color(0xFF1A1A1A),
              numberColor: const Color(0xFF1A1A1A),
              rightLabel: 'Right',
              leftLabel: 'Left',
              labelColor: const Color(0xFF1A1A1A),
              onSelected: (teeth) => setState(() => _selected = teeth),
            ),
          ),
        ),
      ],
    );
  }
}
