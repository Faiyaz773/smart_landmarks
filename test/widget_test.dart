import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_landmarks/main.dart';

void main() {
  setUpAll(() async {
    await initializeAppDependencies();
  });

  testWidgets('SmartLandmarks app builds with navigation', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Landmarks'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Add/View'), findsOneWidget);
  });
}
