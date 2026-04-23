import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/main.dart';

void main() {
  testWidgets('FitTrackApp renders without crashing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitTrackApp()));
    // Let a few frames settle; we don't pumpAndSettle because the router
    // redirect relies on async secure storage reads.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });
}
