class MoneyUtils {
  const MoneyUtils._();

  static double round2(double value) {
    if (value.isNaN || value.isInfinite) return 0;
    return (value * 100).roundToDouble() / 100;
  }

  static double round4(double value) {
    if (value.isNaN || value.isInfinite) return 0;
    return (value * 10000).roundToDouble() / 10000;
  }
}
