import 'package:flutter/material.dart';

/// The app icon: the fountain-pen nib in a light circle on the navy
/// background, exactly as in the launcher icon.
class AppIconImage extends StatelessWidget {
  const new({this.size = 112, super.key});

  static const asset = 'assets/icon/ios_icon_1024.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          asset,
          width: size,
          height: size,
          cacheWidth: (size * 3).round(),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
