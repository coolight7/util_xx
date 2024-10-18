// ignore_for_file: file_names, camel_case_types, non_constant_identifier_names, constant_identifier_names

import "dart:convert" as convert;
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'MyLogger.dart';

enum MyFormatDurationType_e {
  /// [HH:]MM:SS
  hhMMSS,

  /// HH:MM:SS
  HHMMSS,

  /// HH:MM
  HHMM,

  AutoHM,

  /// MM:SS
  MMSS,
}

enum MySeparatorType_e {
  /// 文字
  Char,

  /// 符号
  Symbol,
}

class MyParse_c {
  MyParse_c._();

  // 将List<dy> 转List<int>
  static List<int> parseListDynamicToInt(List<dynamic> in_list) {
    List<int> ids = [];
    for (int i = 0; i < in_list.length; ++i) {
      final item = in_list[i];
      if (item is int) {
        ids.add(item);
      } else {
        final intItem = int.tryParse(item.toString());
        if (null != intItem) {
          ids.add(intItem);
        }
      }
    }
    return ids;
  }

  static List<int> parseListItemToInt<T>(
    List<T> in_list,
    int Function(T item) toInt,
  ) {
    List<int> ids = [];
    for (int i = 0; i < in_list.length; ++i) {
      ids.add(toInt.call(in_list[i]));
    }
    return ids;
  }

  static List<T> parseListIntToEnum<T>(
    List<int> in_list,
    T? Function(int item) toEnum,
  ) {
    List<T> ids = [];
    for (int i = 0; i < in_list.length; ++i) {
      final item = toEnum.call(in_list[i]);
      if (null != item) {
        ids.add(item);
      }
    }
    return ids;
  }

  static List<int>? tryParseStringToListInt(String data) {
    try {
      return MyParse_c.parseListDynamicToInt(convert.jsonDecode(data));
    } catch (e) {
      MyLogger.to().severe(MyLogItem(
        prefix: "json 解析错误",
        msg: [e.toString(), data],
      ));
      return null;
    }
  }

  static int parseTimeOfDay2Minute(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  static TimeOfDay parseMinute2TimeOfDay(int time) {
    return TimeOfDay(
      hour: time ~/ 60,
      minute: time % 60,
    );
  }

  static T? parseIntStr2Enum<T>(String? str, T? Function(int) toEnum) {
    if (null != str) {
      final typeInt = int.tryParse(str);
      if (null != typeInt) {
        return toEnum.call(typeInt);
      }
    }
    return null;
  }

  /// 将字符串转回颜色值
  static Color? parseString2Color(String? str) {
    if (null == str) {
      return null;
    }
    // #AARRGGBB
    // 去掉可能存在的开头 #
    if (str.startsWith('#')) {
      str = str.substring(1);
    }
    // 按16进制解析
    var num = int.tryParse(str, radix: 16);
    if (null != num) {
      // 拼接透明度
      if (num < 0xFFFFFF && str.length <= 6) {
        num += 0xFF000000;
      }
      return Color(num);
    }
    return null;
  }

  /// 将颜色转为字符串
  static String? parseColor2String(Color? color) {
    if (color == null) {
      return null;
    }
    var aa = color.alpha.toRadixString(16);
    if (aa.length == 1) {
      aa = "0$aa";
    }
    var rr = color.red.toRadixString(16);
    if (rr.length == 1) {
      rr = "0$rr";
    }
    var gg = color.green.toRadixString(16);
    if (gg.length == 1) {
      gg = "0$gg";
    }
    var bb = color.blue.toRadixString(16);
    if (bb.length == 1) {
      bb = "0$bb";
    }
    return "#$aa$rr$gg$bb";
  }

  // 转换形如 hh:mm:ss 的字符串为 秒值
  static int parseDurationStr2Seconds(String str) {
    final datalist = str.split(':');
    int renum = 0;
    int level = 1;
    for (int i = datalist.length; i-- > 0;) {
      final item = int.tryParse(datalist[i]);
      if (null != item) {
        renum += item * level;
      }
      level *= 60;
    }
    return renum;
  }

  static String? tryFormatDurationToStr(
    Duration? duration, {
    MyFormatDurationType_e type = MyFormatDurationType_e.hhMMSS,
    MySeparatorType_e separator = MySeparatorType_e.Symbol,
  }) {
    if (null == duration) {
      return null;
    }
    return formatDurationToStr(
      duration,
      type: type,
      separator: separator,
    );
  }

  /// 将Duration转[HH:]MM:SS格式的字符串
  ///
  static String formatDurationToStr(
    Duration duration, {
    MyFormatDurationType_e type = MyFormatDurationType_e.hhMMSS,
    MySeparatorType_e separator = MySeparatorType_e.Symbol,
  }) {
    String hours = "", minutes = "", seconds = "";
    switch (type) {
      case MyFormatDurationType_e.hhMMSS:
        if (duration.inHours > 0) {
          hours = duration.inHours.toString().padLeft(0, '2');
        }
        minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
        seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
        break;
      case MyFormatDurationType_e.HHMMSS:
        hours = duration.inHours.toString().padLeft(2, '0');
        minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
        seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
        break;
      case MyFormatDurationType_e.HHMM:
        hours = duration.inHours.toString().padLeft(2, '0');
        minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
        break;
      case MyFormatDurationType_e.AutoHM:
        if (duration.inHours > 0) {
          hours = duration.inHours.toString();
        }
        final mm = duration.inMinutes.remainder(60);
        if (mm > 0) {
          minutes = mm.toString();
        }
        break;
      case MyFormatDurationType_e.MMSS:
        minutes = duration.inMinutes.toString().padLeft(2, '0');
        seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    }
    String restr = "";
    switch (separator) {
      case MySeparatorType_e.Char:
        if (hours.isNotEmpty) {
          restr += "$hours小时";
        }
        if (minutes.isNotEmpty) {
          restr += "$minutes分钟";
        }
        if (seconds.isNotEmpty) {
          restr += "$seconds秒";
        }
        break;
      case MySeparatorType_e.Symbol:
        if (hours.isNotEmpty) {
          restr += hours;
        }
        if (minutes.isNotEmpty) {
          if (restr.isNotEmpty) {
            restr += ":";
          }
          restr += minutes;
        }
        if (seconds.isNotEmpty) {
          if (restr.isNotEmpty) {
            restr += ":";
          }
          restr += seconds;
        }
    }
    return restr;
  }

  static String formatTimeToStr(DateTime time) {
    return "${time.hour..toString().padLeft(2, '0')}:${time.minute..toString().padLeft(2, '0')}:${time.second..toString().padLeft(2, '0')}";
  }

  static String formatNumStr(int num) {
    if (num < 10000) {
      return num.toString();
    } else if (num < 10000 * 10000) {
      // 小于 1 亿
      return "${(num / 10000).toStringAsFixed(1)}万";
    } else {
      return "${(num / 10000 / 10000).toStringAsFixed(1)}亿";
    }
  }

  static String? tryFormatFileSizeToStr(
    int? fileSize, {
    int position = 2,
    int scale = 1024,
    int specified = -1,
  }) {
    if (null == fileSize) {
      return null;
    }
    return formatFileSizeToStr(
      fileSize,
      position: position,
      scale: scale,
      specified: specified,
    );
  }

  /// 格式化输出文件大小，自动转为人性化的单位输出
  static String formatFileSizeToStr(
    int fileSize, {
    int position = 2,
    int scale = 1024,
    int specified = -1,
  }) {
    ///格式化数字 如果小数后面为0则不显示小数点
    ///[num]要格式化的数字 double 类型
    /// [position] 保留几位小数 int类型
    String formatNum({
      required double num,
      required int position,
    }) {
      String numStr = num.toString();
      int dotIndex = numStr.indexOf(".");

      ///当前数字有小数且需要小数位数小于需要的 直接返回当前数字
      if (num % 1 != 0 && (numStr.length - 1 - dotIndex < position)) {
        return numStr;
      }
      int numbs = math.pow(10, position).toInt();
      //模运算 取余数
      double remainder = num * numbs % numbs;
      //小数点后位数如果小于0则表示只保留整数,余数小于1不会进位防止出现200.01保留一位小数出现200.0的情况
      if (position > 0 && remainder >= 0.5) {
        return num.toStringAsFixed(position);
      }
      return num.toStringAsFixed(0);
    }

    double num = fileSize.toDouble();
    List sizeUnit = ["B", "KB", "MB", "GB", "TB", "PB"];
    // if (fileSize is String) {
    //   num = double.parse(fileSize);
    // } else if (fileSize is int || fileSize is double) {
    //   num = fileSize;
    // }
    //获取他的单位
    if (num > 0) {
      int unit = math.log(num) ~/ math.log(scale);
      if (specified >= 0 && specified < sizeUnit.length) {
        unit = specified;
      }
      double size = num / math.pow(scale, unit);
      String numStr = formatNum(num: size, position: position);
      return "$numStr ${sizeUnit[unit]}";
    }
    return "0 B";
  }

  /// [0, +]
  /// * 只允许自然数（0、正整数）通过，负数返回null
  static int? assertUInt(int? in_num) {
    if (null != in_num && in_num >= 0) {
      return in_num;
    }
    return null;
  }

  /// [1, +]
  /// * 只允许正整数通过，0、负数返回null
  static int? assertPositiveInt(int? in_num) {
    if (null != in_num && in_num > 0) {
      return in_num;
    }
    return null;
  }
}
