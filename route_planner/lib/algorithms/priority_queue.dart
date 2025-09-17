class PriorityQueue<T> {
  final List<T> _heap = [];
  final int Function(T, T) _compare;

  PriorityQueue(this._compare);

  bool get isEmpty => _heap.isEmpty;
  bool get isNotEmpty => _heap.isNotEmpty;
  int get length => _heap.length;

  void add(T item) {
    _heap.add(item);
    _siftUp(_heap.length - 1);
  }

  T removeFirst() {
    if (_heap.isEmpty) {
      throw StateError('No element');
    }

    final result = _heap[0];
    final last = _heap.removeLast();

    if (_heap.isNotEmpty) {
      _heap[0] = last;
      _siftDown(0);
    }

    return result;
  }

  T get first {
    if (_heap.isEmpty) {
      throw StateError('No element');
    }
    return _heap[0];
  }

  void _siftUp(int index) {
    while (index > 0) {
      final parentIndex = (index - 1) ~/ 2;
      if (_compare(_heap[index], _heap[parentIndex]) >= 0) {
        break;
      }
      _swap(index, parentIndex);
      index = parentIndex;
    }
  }

  void _siftDown(int index) {
    while (true) {
      final leftChild = 2 * index + 1;
      final rightChild = 2 * index + 2;
      int smallest = index;

      if (leftChild < _heap.length &&
          _compare(_heap[leftChild], _heap[smallest]) < 0) {
        smallest = leftChild;
      }

      if (rightChild < _heap.length &&
          _compare(_heap[rightChild], _heap[smallest]) < 0) {
        smallest = rightChild;
      }

      if (smallest == index) {
        break;
      }

      _swap(index, smallest);
      index = smallest;
    }
  }

  void _swap(int i, int j) {
    final temp = _heap[i];
    _heap[i] = _heap[j];
    _heap[j] = temp;
  }

  List<T> toList() => List.from(_heap);

  Iterable<R> map<R>(R Function(T) f) {
    return _heap.map(f);
  }
}