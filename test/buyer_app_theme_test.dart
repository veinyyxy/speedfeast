import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedfeast/Common/buyer_app_theme.dart';

void main() {
  test('buyer theme parses semantic colors from system config', () {
    final theme = BuyerAppTheme.fromSystemConfigs({
      'ui.theme.buyer': {
        'value': {
          'brightness': 'dark',
          'primary': '#112233',
          'secondary': '#445566',
          'surface': '#101010',
          'background': '#050505',
          'error': '#AA0000',
        },
      },
    });

    expect(theme.brightness, Brightness.dark);
    expect(theme.primary, const Color(0xFF112233));
    expect(theme.background, const Color(0xFF050505));
    expect(theme.toThemeData().colorScheme.secondary, const Color(0xFF445566));
  });

  test('buyer theme falls back when a color is malformed', () {
    final theme = BuyerAppTheme.fromSystemConfigs({
      'ui.theme.buyer': {
        'value': {'primary': 'blue'},
      },
    });

    expect(theme.primary, BuyerAppTheme.fallback.primary);
  });
}
