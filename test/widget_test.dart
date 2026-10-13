import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:run_tracker/main.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for headless desktop test environment
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Run tracker smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RunTrackerApp());
    await tester.pump();
    expect(find.text('RUN TRACKER'), findsOneWidget);
  });
}
