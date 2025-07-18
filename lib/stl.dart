import 'dart:collection';

import 'package:string_util_xx/StringUtilxx.dart';

/// 不对可重复的键值对进行支持
typedef IgnoreCaseMap<T> = HashMap<String, T>;
typedef IgnoreCaseSet = HashSet<String>;

class STLxx_c {
  STLxx_c._();

  static IgnoreCaseMap<T> createIgnoreCaseMap<T>({Map<String, T>? data}) {
    final result = IgnoreCaseMap<T>(
      equals: (p0, p1) {
        return StringUtilxx_c.isIgnoreCaseEqual(p0, p1);
      },
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

  static IgnoreCaseSet createIgnoreCaseSet({Set<String>? data}) {
    final result = IgnoreCaseSet(
      equals: (p0, p1) {
        return StringUtilxx_c.isIgnoreCaseEqual(p0, p1);
      },
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
  final int startIndex;
  final int patternIndex;

  ACMatch(this.startIndex, this.patternIndex);
}

class _TrieNode {
  final Map<int, int> children = {}; // 使用Map支持Unicode
  int fail = -1;
  final List<int> outputs = [];
}

class AhoCorasick {
  final List<_TrieNode> _nodes = [];
  final List<String> _patterns = [];

  AhoCorasick(Iterable<String> patterns) {
    _nodes.add(_TrieNode()); // 根节点

    for (final pattern in patterns) {
      addPattern(pattern);
    }
    build();
  }

  void addPattern(String pattern) {
    _patterns.add(pattern);
    int current = 0;

    for (final char in pattern.runes) {
      // 如果当前节点没有该字符的子节点，则创建新节点
      if (!_nodes[current].children.containsKey(char)) {
        _nodes[current].children[char] = _nodes.length;
        _nodes.add(_TrieNode());
      }
      current = _nodes[current].children[char]!;
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

    // 使用runes处理Unicode字符
    final runes = text.runes.toList();

    for (var i = 0; i < runes.length; i++) {
      final char = runes[i];

      // 跳转失败指针直到找到匹配或回到根节点
      while (current > 0 && !_nodes[current].children.containsKey(char)) {
        current = _nodes[current].fail;
      }

      // 移动到下一个节点
      if (_nodes[current].children.containsKey(char)) {
        current = _nodes[current].children[char]!;
      } else {
        current = 0; // 没有匹配时回到根节点
      }

      // 收集所有匹配的模式
      for (final patternId in _nodes[current].outputs) {
        final patternLength = _patterns[patternId].runes.length;
        final startIndex = i - patternLength + 1;
        if (startIndex >= 0) {
          matches.add(ACMatch(startIndex, patternId));
          if (onlyContains) return matches;
        }
      }
    }
    return matches;
  }

  String removeAll(String text) {
    final matches = search(text);
    if (matches.isEmpty) {
      return text;
    }

    // 升序排列
    matches.sort((a, b) {
      final subIndex = a.startIndex - b.startIndex;
      if (subIndex != 0) {
        return subIndex;
      }
      return (_patterns[a.patternIndex].length -
          _patterns[b.patternIndex].length);
    });
    var result = "";
    int index = 0;
    for (final match in matches) {
      if (match.startIndex > index) {
        result += text.substring(index, match.startIndex);
      }
      final end = match.startIndex + _patterns[match.patternIndex].length;
      if (end > index) {
        index = end;
      }
    }
    if (index < text.length) {
      result += text.substring(index);
    }

    return result;
  }
}
