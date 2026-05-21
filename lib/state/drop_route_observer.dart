import 'package:flutter/widgets.dart';

class DropRouteObserver extends NavigatorObserver {
  String? _currentRouteName;

  String? get currentRouteName => _currentRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _currentRouteName = route.settings.name;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _currentRouteName = previousRoute?.settings.name;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _currentRouteName = newRoute?.settings.name;
  }
}

final dropRouteObserver = DropRouteObserver();
