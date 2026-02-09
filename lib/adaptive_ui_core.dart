import 'package:flutter/widgets.dart';

class AdaptiveUI {
  final double _width;
  final double _height;
  final double _textScale;
  final double _scale;

  AdaptiveUI._(
      this._width,
      this._height,
      this._textScale,
      this._scale,
      );

  /// factory: MediaQuery sirf yahin
  factory AdaptiveUI.of(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;
    final textScale = media.textScaleFactor;

    return AdaptiveUI._(
      width,
      height,
      textScale,
      _calculateScale(width),
    );
  }

  /// device-based scaling
  static double _calculateScale(double width) {
    if (width < 360) return 0.85;   // small phones
    if (width < 411) return 1.0;    // normal phones
    if (width < 600) return 1.1;    // large phones
    return 1.25;                   // tablet
  }

  // ---------- UI helpers ----------
  double w(double v) => v * _scale;
  double h(double v) => v * _scale;

  double sp(double v) {
    final safeTextScale = _textScale.clamp(1.0, 1.2);
    return v * _scale * safeTextScale;
  }

  double r(double v) => v * _scale;

  EdgeInsets pad(double v) => EdgeInsets.all(w(v));

  EdgeInsets padSym({double h = 0, double v = 0}) =>
      EdgeInsets.symmetric(
        horizontal: w(h),
        vertical: w(v),
      );

  // ---------- device info ----------
  bool get isSmallPhone => _width < 360;
  bool get isMediumPhone => _width >= 360 && _width < 411;
  bool get isLargePhone => _width >= 411 && _width < 600;
  bool get isTablet => _width >= 600;
}
