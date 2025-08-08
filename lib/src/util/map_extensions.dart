extension MapMergeExtension<K, V> on Map<K, V> {
  void merge(Map<K, V> other) {
    for (final e in other.entries) {
      if (!containsKey(e.key) ||
          this[e.key] is! Map<K, V> ||
          e.value is! Map<K, V>) {
        this[e.key] = e.value;
      } else if (V == dynamic || V == Map<K, V>) {
        final child = <K, V>{};
        child.addAll(this[e.key] as Map<K, V>);
        child.merge(e.value as Map<K, V>);
        this[e.key] = child as V;
      } else {
        // Overwrite
        this[e.key] = e.value;
      }
    }
  }

  Map<K, V> mergedWith(Map<K, V> other) {
    final result = <K, V>{};
    result.merge(this);
    result.merge(other);
    return result;
  }
}

typedef MapKeyReducer<K> = K Function(K k1, K k2);

extension MapFlattenExtension<K, V> on Map<K, V> {
  Map<K, V> flatten(MapKeyReducer<K> keyReducer) {
    final result = <K, V>{};
    for (final e in entries) {
      if (e.value is Map<K, V>) {
        for (final e2 in (e.value as Map<K, V>).flatten(keyReducer).entries) {
          result[keyReducer(e.key, e2.key)] = e2.value;
        }
      } else {
        result[e.key] = e.value;
      }
    }

    return result;
  }
}
