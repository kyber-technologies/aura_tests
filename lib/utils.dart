import 'package:aura_dart/common.dart';
import 'package:aura_dart/resource.dart';
import 'package:grpc/grpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';

typedef ErrorType = Error_Type;

final ResourceId defaultIconResource = ResourceId(
  namespace: ResourceNamespace(aura: Empty()),
  key: 'default_icon.png',
);

CallOptions authOptions(String token) =>
    CallOptions(metadata: <String, String>{'Authorization': token});

void assertMap<T, U>(Map<T, U> a, Map<T, U> b) {
  assert(
    a.length == b.length,
    'Expected map with length ${a.length}, but found ${b.length}',
  );

  for (final MapEntry<T, U> entry in a.entries) {
    assert(
      b.containsKey(entry.key),
      'Expected key ${entry.key}, but none was found',
    );
    assert(
      b[entry.key] == entry.value,
      'Expected value ${entry.value}, but found ${b[entry.key]}',
    );
  }
}

void assertList<T1, T2>(
  List<(T1, T2)> values, {
  bool Function(T1, T2)? comparator,
  void Function(T1, T2)? asserter,
}) {
  for (final (int index, (T1 a, T2 b)) in values.indexed) {
    if (comparator != null) {
      assert(comparator(a, b), 'Expected $a, but found $b (at index $index)');
    } else if (asserter != null) {
      asserter(a, b);
    } else {
      assert(a == b, 'Expected $a, but found $b (at index $index)');
    }
  }
}

void assertLists<T1, T2>(
  List<T1> as,
  List<T2> bs, {
  bool Function(T1, T2)? comparator,
  void Function(T1, T2)? asserter,
}) {
  assert(
    as.length == bs.length,
    'Expected length ${as.length}, but found ${bs.length}',
  );

  for (final (int index, T1 a) in as.indexed) {
    final T2 b = bs[index];

    if (comparator != null) {
      assert(comparator(a, b), 'Expected $a, but found $b (at index $index)');
    } else if (asserter != null) {
      asserter(a, b);
    } else {
      assert(a == b, 'Expected $a, but found $b (at index $index)');
    }
  }
}

extension ChunkedList<T> on List<T> {
  Iterable<List<T>> chunked(int size) sync* {
    for (int i = 0; i < length; i += size) {
      yield sublist(i, i + size > length ? length : i + size);
    }
  }
}
