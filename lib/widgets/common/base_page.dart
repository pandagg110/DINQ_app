import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

abstract class BasePage {}

class AssetImageView extends StatelessWidget {
  final String name;
  final String ex;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Alignment alignment;

  const AssetImageView(
    this.name, {
    super.key,
    this.ex = "png",
    this.fit,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    var imagePath = "assets/images/$name.$ex";
    return Image.asset(imagePath, fit: fit, width: width, height: height, alignment: alignment);
  }
}

class NetworkImageView extends StatelessWidget {
  const NetworkImageView({
    super.key,
    required this.imageUrl,
    this.placeholder,
    this.width,
    this.height,
    this.borderRadius,
    this.fit,
    this.alignment = Alignment.center,
    this.fadeInDuration = const Duration(milliseconds: 50),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.imageBuilder,
  });

  final String? imageUrl;
  final Widget? placeholder;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final BorderRadius? borderRadius;
  final Duration fadeInDuration;
  final Duration? fadeOutDuration;
  final ImageWidgetBuilder? imageBuilder;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (imageUrl?.isEmpty ?? true) {
      child = placeholder ?? SizedBox(width: width, height: height);
    } else {
      try {
        child = CachedNetworkImage(
          imageUrl: imageUrl!,
          width: width,
          height: height,
          fit: fit ?? BoxFit.cover,
          fadeInDuration: fadeInDuration,
          alignment: alignment,
          fadeOutDuration: fadeOutDuration,
          useOldImageOnUrlChange: true,
          placeholder: (context, url) {
            return placeholder ?? Container();
          },
          errorWidget: (context, url, error) {
            return placeholder ?? Container();
          },
          imageBuilder: imageBuilder,
        );
      } catch (err) {
        child = placeholder ?? SizedBox(width: width, height: height);
      }
    }
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}

class NormalButton extends StatelessWidget {
  final GestureTapCallback onTap;

  final Widget child;

  final EdgeInsetsGeometry? padding;

  const NormalButton({super.key, required this.child, required this.onTap, this.padding});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      radius: 0.0,
      onTap: onTap,
      child: Container(padding: padding, child: child),
    );
  }
}
