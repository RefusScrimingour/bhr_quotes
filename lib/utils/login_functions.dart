import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

/// Creates the header for a login page using an image.
HeaderBuilder headerImage(String assetName) {
  return (context, constraints, _) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SvgPicture.asset(assetName, semanticsLabel: 'Maths Club Logo'),
    );
  };
}

/// Creates the header for a login page using an icon.
HeaderBuilder headerIcon(BuildContext context, IconData icon) {
  return (context, constraints, shrinkOffset) {
    return Padding(
      padding: const EdgeInsets.all(20).copyWith(top: 40),
      child: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: constraints.maxWidth / 4 * (1 - shrinkOffset),
      ),
    );
  };
}

/// Creates the side image for a login page using an image.
SideBuilder sideImage(String assetName) {
  return (context, constraints) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(constraints.maxWidth / 4),
        child: SvgPicture.asset(assetName, semanticsLabel: 'Maths Club Logo'),
      ),
    );
  };
}

/// Creates the side image for a login page using an icon.
SideBuilder sideIcon(BuildContext context, IconData icon) {
  return (context, constraints) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: constraints.maxWidth / 3,
      ),
    );
  };
}
