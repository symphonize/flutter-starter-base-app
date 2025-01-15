import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_starter_base_app/src/api/mock_api.dart';
import 'package:country_code/country_code.dart';

void main() {
  setUpAll(WidgetsFlutterBinding.ensureInitialized);

  test('get_countries', () async {
    final response = await APIMock().getCountries();
    if (response.length > 1) {
      expect(CountryCode.values.map((e) => e.alpha2).toList().contains(response[0].code), true);
    }
    if (response.length > 2) {
      expect(CountryCode.values.map((e) => e.alpha2).toList().contains(response[1].code), true);
    }
  });
}
