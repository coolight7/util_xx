/*
//                      __     __
//                     0__0o0o0__0
//                      o8888888o
//                     88"  *  "88
//                     (| /\ /\ |)
//                      0\  _  /0
//                    ___/`---'\___
//                  .' \\|     |// '.
//                 / \\|||  :  |||// \
//                / _||||| -:- |||||- \
//               |   | \\\  -  /// |   |
//               | \_|  ''\---/''  |_/ |
//               \  .-\__  '-'  ___/-. /
//             ___'. .'  /--.--\  `. .'___
//          ."" '<  `.___\_<|>_/___.' >' "".
//         | | :  `- \`.;`\ _ /`;.`/ - ` : | |
//         \  \ `_.   \_ __\ /__ _/   .-` /  /
//     =====`-.____`.___ \_____/___.-`___.-'=====
//                       `=---='
//
//     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//               天依保佑         永无BUG
*/

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 套娃类，用于包裹某元素，方便进行类似c++引用传递修改
class MyObj_c<T> {
  T value;
  MyObj_c(this.value);

  static T1? autoFromJson<T1>(
    dynamic json,
    T1 Function(Map<String, dynamic>) fromJson,
    T1 Function(String) fromJsonStr,
  ) {
    if (json is String && json.isNotEmpty) {
      return fromJsonStr(json);
    } else if (json is Map<String, dynamic>) {
      return fromJson(json);
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    return value == other;
  }

  @override
  int get hashCode => value.hashCode;

  dynamic toJson() {
    try {
      return (value as dynamic)?.toJson();
    } on Exception catch (_) {
      throw Exception("$T has not method [toJson]");
    }
  }
}

class MyUtil_c {
  static final random = math.Random();

  static void defEmptyFunction_0() {}
  static void defEmptyFunction_1(_) {}

  /// 二路归并
  /// * [fun] 返回 > 0 则代表 [left] 和 [right] 应当交换位置
  /// * 即 最终结果的数组中，(An - An-1) >= 0; (An-1 - An-2) >= 0; ...; A1 - A0 >= 0
  static List<T> mergeSort<T>(List<T> list, int Function(T left, T right) fun) {
    if (list.length < 2) {
      return list;
    } else if (list.length == 2) {
      final result = fun(list.first, list.last);
      if (result > 0) {
        final temp = list.first;
        list.first = list.last;
        list.last = temp;
      }
      return list;
    } else {
      final relist1 = mergeSort(list.sublist(0, list.length ~/ 2), fun);
      final relist2 = mergeSort(list.sublist(list.length ~/ 2), fun);
      final relist = <T>[];
      for (int i = 0, j = 0;;) {
        if (i < relist1.length && j < relist2.length) {
          if (fun(relist1[i], relist2[j]) <= 0) {
            relist.add(relist1[i]);
            ++i;
          } else {
            relist.add(relist2[j]);
            ++j;
          }
        } else if (i < relist1.length) {
          relist.addAll(relist1.sublist(i));
          break;
        } else if (j < relist2.length) {
          relist.addAll(relist2.sublist(j));
          break;
        } else {
          break;
        }
      }
      return relist;
    }
  }

  static Uri? tryParseFullUri(String in_url) {
    final url = Uri.tryParse(in_url);
    if (null != url) {
      if (url.scheme.isNotEmpty) {
        return url;
      }
    }
    return null;
  }

  /// 计算Text组件的宽高
  static Size countTextWidgetSize(
    String text,
    TextStyle style, {
    int maxLines = 2 ^ 31,
    double maxWidth = double.infinity,
  }) {
    if (text.isEmpty) {
      return Size.zero;
    }
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textWidthBasis: TextWidthBasis.longestLine,
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth);
    return textPainter.size;
  }

  static Color shiftColor(Color color, int shift) {
    return Color.fromRGBO(
      math.max(color.red + shift, 0),
      math.max(color.green + shift, 0),
      math.max(color.blue + shift, 0),
      1,
    );
  }

  /// 让[useColor]和[fromColor]保持 [sub]以上 的距离
  static Color awaySetColor(
    Color? useColor,
    Color fromColor,
    int sub, {
    bool toUpper = true,
  }) {
    if (null == useColor) {
      return shiftColor(fromColor, sub);
    }
    int subPoint(int usePoint, int fromPoint, int limit) {
      final sub = usePoint - fromPoint;
      if (limit < 0) {
        limit = -limit;
      }
      if (sub <= limit && sub >= -limit) {
        if (toUpper) {
          return math.min((math.max(usePoint, fromPoint) + limit), 255);
        } else {
          return math.max((math.min(usePoint, fromPoint) - limit), 0);
        }
      }
      return usePoint;
    }

    return Color.fromRGBO(
      subPoint(useColor.red, fromColor.red, sub),
      subPoint(useColor.green, fromColor.green, sub),
      subPoint(useColor.blue, fromColor.blue, sub),
      1,
    );
  }

  /// 让[useColor]和[fromColor]保持 [sub] 以内 的距离
  static Color nearSetColor(
    Color? useColor,
    Color fromColor,
    int sub,
  ) {
    if (null == useColor) {
      return fromColor;
    }
    int subPoint(int usePoint, int fromPoint, int limit) {
      final sub = usePoint - fromPoint;
      if (limit < 0) {
        limit = -limit;
      }
      if (sub <= limit && sub >= -limit) {
        return usePoint;
      }
      final rePoint = fromPoint + ((sub > 0) ? limit : -limit);
      if (rePoint < 0) {
        return 0;
      } else if (rePoint > 255) {
        return 255;
      } else {
        return rePoint;
      }
    }

    return Color.fromRGBO(
      subPoint(useColor.red, fromColor.red, sub),
      subPoint(useColor.green, fromColor.green, sub),
      subPoint(useColor.blue, fromColor.blue, sub),
      1,
    );
  }

  /// 在 [minDuration] - [maxDuration] 之间随机取值延时等待
  static Future<void> randomTimeDelayed({
    required Duration minDuration,
    required Duration maxDuration,
  }) {
    assert(maxDuration.inMilliseconds >= minDuration.inMilliseconds);
    return Future.delayed(Duration(
      milliseconds: random.nextInt(
            maxDuration.inMilliseconds - minDuration.inMilliseconds,
          ) +
          minDuration.inMilliseconds,
    ));
  }
}
