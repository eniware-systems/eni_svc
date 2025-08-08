import 'package:eni_svc/src/util/map_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('map flattening is working', () {
    final Map<String, dynamic> a = {
      "a": <String, dynamic>{
        "b": 1,
        "c": <String, dynamic>{"d": 2}
      }
    };

    final Map<String, dynamic> expected = {
      "a.b": 1,
      "a.c.d": 2,
    };

    final result = a.flatten((k1, k2) => "$k1.$k2");

    expect(result, equals(expected));
  });
}
