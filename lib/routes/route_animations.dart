import 'package:flutter/material.dart';

class RouteAnimation {
  static PageRouteBuilder slideFade(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.08),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        );

        final fadeAnimation = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
    );
  }
}
