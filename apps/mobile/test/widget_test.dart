import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/main.dart';

void main() {
  testWidgets('FitTrackApp mounts the landing screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitTrackApp()));
    await tester.pumpAndSettle();

    expect(find.text('FitTrack'), findsOneWidget);
  });
}
