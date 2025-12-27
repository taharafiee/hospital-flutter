import 'package:flutter/material.dart';

enum RouteType {
  patient,
  doctor,
  admin,
  back,
}

class SmartRoute {
  static PageRouteBuilder go(
    Widget page, {
    RouteType type = RouteType.patient,
  }) {
    late Offset begin;
    late Curve curve;
    const duration = Duration(milliseconds: 420);

    switch (type) {
      case RouteType.doctor:
        begin = const Offset(1, 0); // از راست
        curve = Curves.easeInOutCubic;
        break;

      case RouteType.back:
        begin = const Offset(0, -0.06); // بالا به پایین
        curve = Curves.easeIn;
        break;
case RouteType.admin:
  begin = const Offset(0, 1); // از پایین
  curve = Curves.easeInOutCubic;
  break;

      case RouteType.patient:
      default:
        begin = const Offset(0, 0.08); // پایین به بالا
        curve = Curves.easeOutCubic;
        
    }

    return PageRouteBuilder(
      transitionDuration: duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final slide = Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        final fade = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: child,
          ),
        );
      },
    );
  }
}
