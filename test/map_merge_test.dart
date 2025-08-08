import 'package:eni_svc/src/util/map_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('map deep merge is working', () {
    final Map<String, dynamic> a = {
      "a": 1,
      "b0": <String, dynamic>{"b1": 2, "c1": <String, dynamic>{}}
    };

    final Map<String, dynamic> b = {
      "a": 1,
      "b0": <String, dynamic>{
        "b2": 3,
        "c1": <String, dynamic>{"c2": 4}
      }
    };

    final Map<String, dynamic> expected = {
      "a": 1,
      "b0": <String, dynamic>{
        "b1": 2,
        "b2": 3,
        "c1": <String, dynamic>{"c2": 4}
      }
    };

    a.merge(b);
    expect(a, equals(expected));
  });

  test('merge is commutative when no properties are overwritten', () {
    final Map<String, dynamic> a = {
      "a": 1,
      "b0": <String, dynamic>{"b1": 2, "c1": <String, dynamic>{}}
    };

    final Map<String, dynamic> b = {
      "a": 1,
      "b0": <String, dynamic>{
        "b2": 3,
        "c1": <String, dynamic>{"c2": 4}
      }
    };

    final ab = a.mergedWith(b);
    final ba = b.mergedWith(a);
    expect(ab, equals(ba));
  });

  test('merge overwrites existing properties', () {
    final Map<String, dynamic> a = {
      "a": 1,
      "b": <String, dynamic>{"b1": 2}
    };

    final Map<String, dynamic> b = {"a": 5, "b": -2};

    a.merge(b);
    expect(a, equals(b));
  });

  test('merge self preserves identity', () {
    final Map<String, dynamic> a = {
      "a": 1,
      "b": <String, dynamic>{"b1": 2}
    };

    expect(a.mergedWith(a), equals(a));
  });
}
