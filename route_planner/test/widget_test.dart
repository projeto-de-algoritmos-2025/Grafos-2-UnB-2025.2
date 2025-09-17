// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:route_planner/main.dart';

void main() {
  testWidgets('Route planner app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify the app loads with the expected title
    expect(find.text('Route Planner - Dijkstra Demo'), findsOneWidget);

    // Verify initial instructions are shown
    expect(find.text('1. Tap on the map to set start point'), findsOneWidget);

    // Verify key UI elements are present
    expect(find.text('Weight Criteria:'), findsOneWidget);
    expect(find.text('Find Route'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
  });
}
