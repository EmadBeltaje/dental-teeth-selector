import 'package:dental_teeth_selector/src/teeth_chart_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('jaw gap separates arches and places side labels', () {
    final data = loadTeethChartData();

    final gap = data.teeth['32']!.rect.top - data.teeth['1']!.rect.bottom;
    expect(gap, greaterThan(400));

    expect(data.rightLabelAnchor.dx, lessThan(data.size.width * 0.35));
    expect(data.leftLabelAnchor.dx, greaterThan(data.size.width * 0.65));

    // Labels sit in the opened gap between jaws.
    expect(data.rightLabelAnchor.dy, greaterThan(data.teeth['1']!.rect.bottom));
    expect(data.rightLabelAnchor.dy, lessThan(data.teeth['32']!.rect.top));
    expect(data.leftLabelAnchor.dy, greaterThan(data.teeth['16']!.rect.bottom));
    expect(data.leftLabelAnchor.dy, lessThan(data.teeth['17']!.rect.top));

    // Not the same point / not chart center.
    expect(
      (data.rightLabelAnchor.dx - data.leftLabelAnchor.dx).abs(),
      greaterThan(1000),
    );
  });
}
