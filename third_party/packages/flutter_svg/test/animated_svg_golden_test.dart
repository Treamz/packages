import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// The same tolerant comparator that the static golden tests use, so that
/// sub-pixel differences between platforms do not fail the suite.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (!result.passed) {
      final String error = await generateFailureOutput(result, golden, basedir);
      if (result.diffPercent >= .06) {
        throw FlutterError(error);
      } else {
        // ignore: avoid_print
        print(
          'Warning - golden differed less than .06% (${result.diffPercent}%), '
          'ignoring failure but producing output\n'
          '$error',
        );
      }
    }
    return true;
  }
}

/// A square that fades from blue to red while it rotates a quarter turn, using
/// SMIL, and a circle that grows using CSS keyframes.
const String _animatedSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">
  <style>
    #dot { animation: grow 4s linear infinite; }
    @keyframes grow { from { r: 5 } to { r: 20 } }
  </style>
  <rect x="10" y="10" width="40" height="40" fill="#0000ff">
    <animate attributeName="fill" from="#0000ff" to="#ff0000" dur="4s"
        repeatCount="indefinite"/>
    <animateTransform attributeName="transform" type="rotate" from="0 30 30"
        to="90 30 30" dur="4s" repeatCount="indefinite"/>
  </rect>
  <circle id="dot" cx="75" cy="75" r="5" fill="#00aa00"/>
</svg>
''';

void main() {
  setUpAll(() {
    final oldComparator = goldenFileComparator as LocalFileComparator;
    final newComparator = _TolerantComparator(Uri.parse('${oldComparator.basedir}test'));
    expect(oldComparator.basedir, newComparator.basedir);
    goldenFileComparator = newComparator;
  });

  setUp(() {
    svg.animationCache.clear();
  });

  testWidgets('AnimatedSvgPicture renders each quarter of its timeline', (
    WidgetTester tester,
  ) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: AnimatedSvgPicture.string(_animatedSvg, frameRate: 1, width: 100, height: 100),
      ),
    );
    await tester.pump();

    for (var quarter = 0; quarter < 4; quarter += 1) {
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('golden_widget/animated.frame_$quarter.png'),
      );
      await tester.pump(const Duration(seconds: 1));
    }
  });
}
