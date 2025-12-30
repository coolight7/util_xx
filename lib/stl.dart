import 'dart:collection';

import 'package:string_util_xx/StringUtilxx.dart';

/// 不对可重复的键值对进行支持
typedef IgnoreCaseMap<T> = HashMap<String, T>;
typedef IgnoreCaseSet = HashSet<String>;

class STLxx_c {
  STLxx_c._();

  static IgnoreCaseMap<T> createIgnoreCaseMap<T>({Map<String, T>? data}) {
    final result = IgnoreCaseMap<T>(
      equals: StringUtilxx_c.isIgnoreCaseEqual,
      hashCode: (p0) {
        return p0.toLowerCase().hashCode;
      },
      isValidKey: (p0) {
        return (p0 is String);
      },
    );
    if (null != data) {
      result.addAll(data);
    }
    return result;
  }

  static IgnoreCaseMap<List<String>> createIgnoreCaseMapValueKey(
      Map<String, String> data) {
    final result = createIgnoreCaseMap<List<String>>();
    for (final item in data.entries) {
      if (item.value.isNotEmpty) {
        if (result.containsKey(item.value)) {
          result[item.value]?.add(item.key);
        } else {
          result[item.value] = [item.key];
        }
      }
    }
    return result;
  }

  static IgnoreCaseSet createIgnoreCaseSet({Iterable<String>? data}) {
    final result = IgnoreCaseSet(
      equals: StringUtilxx_c.isIgnoreCaseEqual,
      hashCode: (p0) {
        return p0.toLowerCase().hashCode;
      },
      isValidKey: (p0) {
        return (p0 is String);
      },
    );
    if (null != data) {
      result.addAll(data);
    }
    return result;
  }
}

class ACMatch {
  final int start;
  final int end;
  final int patternIndex;

  const ACMatch(
    this.start,
    this.end,
    this.patternIndex,
  );

  static int cDefCompare(final ACMatch left, final ACMatch right) {
    if (left.start != right.start) {
      return left.start - right.start;
    }
    return right.end - left.end;
  }

  bool operator <(final ACMatch other) {
    if (start != other.start) {
      return start < other.start;
    }
    return other.end < end;
  }
}

class _TrieNode {
  final Map<int, int> children = {}; // 使用Map支持Unicode
  int fail = -1;
  final List<int> outputs = [];
}

class AhoCorasick {
  static const caseShiftSheet = <int, int>{
    65: 97,
    66: 98,
    67: 99,
    68: 100,
    69: 101,
    70: 102,
    71: 103,
    72: 104,
    73: 105,
    74: 106,
    75: 107,
    76: 108,
    77: 109,
    78: 110,
    79: 111,
    80: 112,
    81: 113,
    82: 114,
    83: 115,
    84: 116,
    85: 117,
    86: 118,
    87: 119,
    88: 120,
    89: 121,
    90: 122,
  };

  final List<_TrieNode> _nodes = [];
  final List<String> _patterns = [];
  final Map<int, int>? shiftSheet;
  final bool caseInsensitive;

  AhoCorasick(
    Iterable<String> patterns, {
    this.shiftSheet,
    this.caseInsensitive = true,
  }) {
    _nodes.add(_TrieNode()); // 根节点

    for (final pattern in patterns) {
      addPattern(pattern);
    }
    build();
  }

  int onCharCode(int char) {
    if (caseInsensitive) {
      // 转换为小写字母
      final result = caseShiftSheet[char];
      if (null != result) {
        return result;
      }
    }
    return shiftSheet?[char] ?? char;
  }

  void addPattern(String pattern) {
    _patterns.add(pattern);
    int current = 0;

    for (final char in pattern.codeUnits) {
      final useChar = onCharCode(char);
      // 如果当前节点没有该字符的子节点，则创建新节点
      if (!_nodes[current].children.containsKey(useChar)) {
        _nodes[current].children[useChar] = _nodes.length;
        _nodes.add(_TrieNode());
      }
      current = _nodes[current].children[useChar]!;
    }
    _nodes[current].outputs.add(_patterns.length - 1);
  }

  String getPattern(int id) {
    return _patterns[id];
  }

  void build() {
    final queue = <int>[];
    _nodes[0].fail = 0;

    // 初始化根节点的子节点
    for (final char in _nodes[0].children.keys) {
      final child = _nodes[0].children[char]!;
      _nodes[child].fail = 0;
      queue.add(child);
    }

    // BFS 构建失败指针
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);

      for (final entry in _nodes[current].children.entries) {
        final char = entry.key;
        final child = entry.value;

        var fail = _nodes[current].fail;

        // 查找失败指针
        while (fail != 0 && !_nodes[fail].children.containsKey(char)) {
          fail = _nodes[fail].fail;
        }

        // 设置子节点的失败指针
        if (fail != 0 && _nodes[fail].children.containsKey(char)) {
          _nodes[child].fail = _nodes[fail].children[char]!;
        } else {
          _nodes[child].fail = 0;
        }

        // 合并输出
        _nodes[child].outputs.addAll(_nodes[_nodes[child].fail].outputs);
        queue.add(child);
      }
    }
  }

  List<ACMatch> search(String text, {bool onlyContains = false}) {
    final matches = <ACMatch>[];
    int current = 0;

    // 使用codeUnits处理Unicode字符
    int index = 0;
    for (final char in text.codeUnits) {
      final useChar = onCharCode(char);
      // 跳转失败指针直到找到匹配或回到根节点
      while (current > 0 && !_nodes[current].children.containsKey(useChar)) {
        current = _nodes[current].fail;
      }

      // 移动到下一个节点
      if (_nodes[current].children.containsKey(useChar)) {
        current = _nodes[current].children[useChar]!;
      } else {
        current = 0; // 没有匹配时回到根节点
      }

      // 收集所有匹配的模式
      for (final patternId in _nodes[current].outputs) {
        final patternLength = _patterns[patternId].codeUnits.length;
        final startIndex = index - patternLength + 1;
        if (startIndex >= 0) {
          matches.add(ACMatch(startIndex, index + 1, patternId));
          if (onlyContains) {
            return matches;
          }
        }
      }
      ++index;
    }
    if (matches.isEmpty) {
      return matches;
    }

    // 升序排列
    matches.sort(ACMatch.cDefCompare);

    final result = <ACMatch>[];
    int lastEnd = -1;
    for (final match in matches) {
      if (match.start >= lastEnd) {
        // 这是一个新的非重叠匹配
        result.add(match);
        lastEnd = match.end;
      }
      // 如果match.start < lastEnd，说明这个匹配与之前的重叠
      // 由于我们已按结束位置降序排序，之前保留的是更长的匹配
      // 所以跳过这个较短的匹配
    }

    return result;
  }

  String removeAll(String text) {
    final matches = search(text, onlyContains: false);
    if (matches.isEmpty) {
      return text;
    }

    int index = 0;
    var result = StringBuffer();
    for (final match in matches) {
      if (match.start > index) {
        result.write(text.substring(index, match.start));
      }
      final end = match.end;
      if (end > index) {
        index = end;
      }
    }
    if (index < text.length) {
      result.write(text.substring(index));
    }

    return result.toString();
  }
}

class LruCachexx_c<TKey, TValue> {
  final int maxSize;
  late Map<TKey, TValue> data;

  LruCachexx_c(
    this.maxSize, {
    Map<TKey, TValue>? data,
  }) {
    this.data = data ?? <TKey, TValue>{};
  }

  TValue? operator [](Object? key) {
    return data[key];
  }

  /// Associates the [key] with the given [value].
  ///
  /// If the key was already in the map, its associated value is changed.
  /// Otherwise the key/value pair is added to the map.
  void operator []=(TKey key, TValue value) {
    data.removeWhere(
      (key, value) => (data.length > (maxSize ~/ 2)),
    );
    data[key] = value;
  }

  void clear() {
    data.clear();
  }
}
