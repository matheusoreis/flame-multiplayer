class Slots<T> {
  final List<T?> _slots;

  Slots(int size) : _slots = List<T?>.filled(size, null, growable: false);

  void _checkIndex(int index) {
    if (index < 0 || index >= _slots.length) {
      throw RangeError('Index out of range: $index');
    }
  }

  T? get(int index) {
    _checkIndex(index);
    return _slots[index];
  }

  Iterable<int> getFilledSlots() sync* {
    for (int i = 0; i < _slots.length; i++) {
      if (_slots[i] != null) {
        yield i;
      }
    }
  }

  Iterable<int> getEmptySlots() sync* {
    for (int i = 0; i < _slots.length; i++) {
      if (_slots[i] == null) {
        yield i;
      }
    }
  }

  void remove(int index) {
    _checkIndex(index);
    _slots[index] = null;
  }

  int add(T value) {
    for (int i = 0; i < _slots.length; i++) {
      if (_slots[i] == null) {
        _slots[i] = value;
        return i;
      }
    }

    throw StateError('No empty slots available');
  }

  int? getFirstEmptySlot() {
    for (int i = 0; i < _slots.length; i++) {
      if (_slots[i] == null) {
        return i;
      }
    }

    return null;
  }

  void update(int index, T value) {
    _checkIndex(index);
    _slots[index] = value;
  }

  T? find(bool Function(T value) predicate) {
    for (var item in _slots) {
      if (item != null && predicate(item)) {
        return item;
      }
    }

    return null;
  }

  List<T> filter(bool Function(T value) predicate) {
    final result = <T>[];

    for (var item in _slots) {
      if (item != null && predicate(item)) {
        result.add(item);
      }
    }

    return result;
  }
}
