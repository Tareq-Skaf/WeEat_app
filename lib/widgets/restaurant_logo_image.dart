import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a restaurant logo image, handling both SVG and raster formats.
/// Falls back to [fallback] widget if the image fails to load.
class RestaurantLogoImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final Widget fallback;
  final BoxFit fit;
  final EdgeInsets padding;

  const RestaurantLogoImage({
    super.key,
    required this.url,
    this.width = double.infinity,
    this.height = double.infinity,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.padding = const EdgeInsets.all(10),
  });

  bool get _isSvg => url != null && url!.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return fallback;

    if (_isSvg) {
      return Padding(
        padding: padding,
        child: SvgPicture.network(
          url!,
          width: width,
          height: height,
          fit: fit,
          placeholderBuilder: (_) => fallback,
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Image.network(
        url!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
