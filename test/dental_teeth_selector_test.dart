import 'package:dental_teeth_selector/src/teeth_chart_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses 32 selectable teeth from the SVG', () {
    final data = loadTeethChartData();

    expect(data.teeth.length, 32);
    expect(data.numberPaths, isNotEmpty);
    expect(data.strokePaths, isNotEmpty);
    expect(data.size.width, greaterThan(0));
    expect(data.size.height, greaterThan(0));

    for (var i = 1; i <= 32; i++) {
      expect(data.teeth.containsKey('$i'), isTrue, reason: 'missing tooth $i');
    }
  });

  test('unites outer and inner contours for multi-path molars', () {
    final data = loadTeethChartData();

    for (final id in ['1', '2', '3', '14', '15', '16']) {
      final tooth = data.teeth[id]!;
      final area = tooth.rect.width * tooth.rect.height;
      expect(
        area,
        greaterThan(150000),
        reason: 'tooth $id should include the outer crown contour',
      );
    }
  });

  test('applies initially selected teeth', () {
    final data = loadTeethChartData();
    data.teeth['8']!.selected = true;
    data.teeth['9']!.selected = true;

    final selected = data.teeth.entries
        .where((e) => e.value.selected)
        .map((e) => e.key)
        .toList();

    expect(selected, containsAll(['8', '9']));
    expect(selected.length, 2);
  });
}
