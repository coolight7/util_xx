extension XXDoubleExpand on double {
  bool approximate(double? other) =>
      (null != other && (this - other).abs() < 0.00001);
}
