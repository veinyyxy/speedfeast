import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedfeast/Common/product_detail.dart';

void main() {
  testWidgets('included product options do not change the displayed price', (
    tester,
  ) async {
    Map<String, List<String>>? selections;

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetail(
          id: 'combo',
          name: 'Best Seller',
          description: 'Combo meal',
          storeName: 'SpeedFeast',
          imageProvider: AssetImage('assets/images/hamberger2.jpg'),
          basePrice: 20,
          optionGroups: [
            const ProductDetailOptionGroup(
              id: 'mains',
              title: 'Choose a main',
              optionsAffectPrice: false,
              options: [
                ProductDetailOption(
                  id: 'burger',
                  title: 'Burger',
                  extraPrice: 8,
                ),
              ],
            ),
          ],
          onSelectionChanged: (value) => selections = value,
        ),
      ),
    );

    await tester.ensureVisible(find.text('Burger'));
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Burger'));
    await tester.pump();

    expect(selections?['mains'], contains('burger'));
    expect(find.text('Included'), findsOneWidget);
    expect(find.text('CA\$28.00'), findsNothing);
    expect(find.text('CA\$20.00'), findsWidgets);
  });
}
