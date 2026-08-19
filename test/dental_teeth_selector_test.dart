import 'package:dental_teeth_selector/dental_teeth_selector.dart';
import 'package:dental_teeth_selector/src/teeth_chart_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses 32 selectable teeth from the SVG', () {
    final data = loadTeethChartData();

    expect(data.teeth.length, 32);
    expect(data.numberPaths, isNotEmpty);
    expect(data.strokePaths, isNotEmpty);
    expect(data.numberCenters.length, 32);
    expect(data.numberFontSize, greaterThan(0));
    expect(data.size.width, greaterThan(0));
    expect(data.size.height, greaterThan(0));

    for (var i = 1; i <= 32; i++) {
      expect(data.teeth.containsKey('$i'), isTrue, reason: 'missing tooth $i');
      expect(
        data.numberCenters.containsKey('$i'),
        isTrue,
        reason: 'missing number center $i',
      );
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

  test('maps Universal ids to European FDI and back', () {
    expect(
      convertToothId(
        '1',
        from: TeethNumberingSystem.universal,
        to: TeethNumberingSystem.european,
      ),
      '18',
    );
    expect(
      convertToothId(
        '8',
        from: TeethNumberingSystem.universal,
        to: TeethNumberingSystem.european,
      ),
      '11',
    );
    expect(
      convertToothId(
        '9',
        from: TeethNumberingSystem.universal,
        to: TeethNumberingSystem.european,
      ),
      '21',
    );
    expect(
      convertToothId(
        '32',
        from: TeethNumberingSystem.universal,
        to: TeethNumberingSystem.european,
      ),
      '48',
    );
    expect(
      convertToothId(
        '18',
        from: TeethNumberingSystem.european,
        to: TeethNumberingSystem.universal,
      ),
      '1',
    );
    expect(
      convertToothIds(
        ['8', '9'],
        from: TeethNumberingSystem.universal,
        to: TeethNumberingSystem.european,
      ),
      ['11', '21'],
    );
  });

  test('convertToothId is identity when systems match', () {
    expect(
      convertToothId(
        '14',
        from: TeethNumberingSystem.universal,
        to: TeethNumberingSystem.universal,
      ),
      '14',
    );
    expect(
      convertToothId(
        '26',
        from: TeethNumberingSystem.european,
        to: TeethNumberingSystem.european,
      ),
      '26',
    );
  });

  testWidgets('fallenTeeth requires showFallenTeeth', (tester) async {
    expect(
      () => DentalTeethSelector(
        showFallenTeeth: false,
        fallenTeeth: const ['1'],
        onSelected: (_) {},
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  testWidgets('fallenTeeth must not overlap initiallySelected', (tester) async {
    expect(
      () => DentalTeethSelector(
        showFallenTeeth: true,
        fallenTeeth: const ['8'],
        initiallySelected: const ['8', '9'],
        onSelected: (_) {},
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  testWidgets('selectingFallenTeeth requires showFallenTeeth', (tester) async {
    expect(
      () => DentalTeethSelector(
        showFallenTeeth: false,
        selectingFallenTeeth: true,
        onSelected: (_) {},
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}
