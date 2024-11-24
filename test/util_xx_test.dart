import 'package:flutter_test/flutter_test.dart';
import 'package:util_xx/Parsexx.dart';

void main() {
  test('adds one to input values', () {});
}

void test_parse() {
  test("test_parse", () {
    expect("18:17:16", Parsexx_c.formatTimeToStr(DateTime.parse("18:17:16")));
    expect("18:17:06", Parsexx_c.formatTimeToStr(DateTime.parse("18:17:06")));
    expect("18:07:06", Parsexx_c.formatTimeToStr(DateTime.parse("18:07:06")));
    expect("08:07:06", Parsexx_c.formatTimeToStr(DateTime.parse("08:07:06")));
    expect("08:07:00", Parsexx_c.formatTimeToStr(DateTime.parse("08:07:00")));
    expect("08:00:00", Parsexx_c.formatTimeToStr(DateTime.parse("08:00:00")));
    expect("00:00:00", Parsexx_c.formatTimeToStr(DateTime.parse("00:00:00")));
  });
}
