import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:speedfeast/Controller/service_provider.dart';
import 'package:speedfeast/main.dart';

void main() {
  testWidgets('buyer app renders with its service provider', (
    WidgetTester tester,
  ) async {
    final serviceProvider = ServiceProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<ServiceProvider>.value(
        value: serviceProvider,
        child: const MyApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
