import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SmartImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;
  final Widget? loadingWidget;

  const SmartImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return errorWidget ?? const Center(child: Icon(Icons.image, color: Colors.grey));
    }

    // Check if it's a base64 data URI
    if (imageUrl.startsWith('data:image')) {
      return _buildBase64Image();
    }

    // Use Image.network with better error handling
    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      headers: const {
        'Accept': 'image/*',
        'Access-Control-Allow-Origin': '*',
      },
      errorBuilder: (context, error, stackTrace) {
        // If the image fails to load, show the error widget
        return errorWidget ?? Container(
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.restaurant, color: Colors.grey)),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return loadingWidget ?? Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
          ),
        );
      },
    );
  }

  Widget _buildBase64Image() {
    try {
      // Extract the base64 part after the comma
      final parts = imageUrl.split(',');
      if (parts.length < 2) {
        return errorWidget ?? const Center(child: Icon(Icons.broken_image, color: Colors.grey));
      }

      final base64String = parts[1];
      final Uint8List bytes = base64Decode(base64String);

      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => errorWidget ?? const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      );
    } catch (e) {
      return errorWidget ?? const Center(child: Icon(Icons.broken_image, color: Colors.grey));
    }
  }
}

class SmartCircleAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Color backgroundColor;
  final Widget? fallbackChild;

  const SmartCircleAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.backgroundColor = Colors.grey,
    this.fallbackChild,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: fallbackChild ?? Icon(Icons.person, size: radius, color: Colors.white),
      );
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final parts = imageUrl.split(',');
        if (parts.length >= 2) {
          final bytes = base64Decode(parts[1]);
          return CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor,
            backgroundImage: MemoryImage(bytes),
          );
        }
      } catch (_) {}
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: NetworkImage(imageUrl),
      onBackgroundImageError: (_, __) {},
      child: fallbackChild ?? Icon(Icons.person, size: radius, color: Colors.white),
    );
  }
}
