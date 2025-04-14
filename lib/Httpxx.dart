import 'dart:collection';

import 'package:string_util_xx/StringUtilxx.dart';

/// 不对可重复的键值对进行支持
typedef IgnoreCaseMap<T> = HashMap<String, T>;
typedef HttpHeaderxx = IgnoreCaseMap<String>;
typedef HttpHeaderAnyxx = Map<String, String>;

class Httpxx_c {
  static HttpHeaderxx createHeader({
    HttpHeaderAnyxx? data,
  }) {
    final result = HttpHeaderxx(
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

  static HttpHeaderxx setHeaders({
    required HttpHeaderxx toHeaders,
    required HttpHeaderAnyxx fromHeaders,
  }) {
    toHeaders.addAll(fromHeaders);
    return toHeaders;
  }
}
