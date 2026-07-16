import 'package:flutter_test/flutter_test.dart';
import 'package:speedfeast/OrderPage/recent_order_page.dart';

void main() {
  group('RecentOrderItem options', () {
    test('groups options and calculates each displayed line total', () {
      final item = RecentOrderItem.fromJson({
        'product_name': 'California',
        'quantity': 1,
        'price': 10.75,
        'selected_options': [
          {
            'group_name': 'Extra adding',
            'option_name': 'Cheese',
            'quantity': 1,
            'unit_price': 1,
          },
          {
            'group_name': 'Extra adding',
            'option_name': 'Avocado',
            'quantity': 2,
            'unit_price': 1,
          },
        ],
      });

      expect(item.optionGroups.keys, ['Extra adding']);
      final options = item.optionGroups['Extra adding']!;
      expect(options, hasLength(2));
      expect(options[0].name, 'Cheese');
      expect(options[0].quantity, 1);
      expect(options[0].totalPrice, 1);
      expect(options[1].name, 'Avocado');
      expect(options[1].quantity, 2);
      expect(options[1].totalPrice, 2);
      expect(item.optionsLabel, 'Extra adding: Cheese, Avocado');
    });

    test('prefers an explicit line total and normalizes invalid quantity', () {
      final explicitTotal = RecentOrderItemOption.fromJson({
        'option_name': 'Bacon',
        'quantity': 3,
        'line_total': 4.5,
        'unit_price': 2,
      });
      final normalizedQuantity = RecentOrderItemOption.fromJson({
        'option_name': 'Sauce',
        'quantity': 0,
        'unit_price': 0.75,
      });

      expect(explicitTotal.quantity, 3);
      expect(explicitTotal.totalPrice, 4.5);
      expect(normalizedQuantity.quantity, 1);
      expect(normalizedQuantity.totalPrice, 0.75);
    });

    test('treats the generic price field as an existing line total', () {
      final option = RecentOrderItemOption.fromJson({
        'option_name': 'Avocado',
        'quantity': 2,
        'price': 2,
      });

      expect(option.quantity, 2);
      expect(option.totalPrice, 2);
    });
  });
}
