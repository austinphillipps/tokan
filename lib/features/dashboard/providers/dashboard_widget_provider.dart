import 'package:flutter/widgets.dart';

/// Manages dashboard widgets that can be injected by plugins or other features.
class DashboardWidgetProvider extends ChangeNotifier {
  final List<Widget> _widgets = [];

  /// Widgets currently registered to display on the dashboard.
  List<Widget> get widgets => List.unmodifiable(_widgets);

  /// Registers a new widget and notifies listeners.
  void addWidget(Widget widget) {
    _widgets.add(widget);
    notifyListeners();
  }

  /// Removes a widget and notifies listeners.
  void removeWidget(Widget widget) {
    _widgets.remove(widget);
    notifyListeners();
  }

  /// Returns true if a widget of type [T] is currently registered.
  bool hasWidgetOfType<T>() {
    return _widgets.any((w) => w is T);
  }

  /// Removes all widgets of type [T] and notifies listeners.
  void removeWidgetOfType<T>() {
    _widgets.removeWhere((w) => w is T);
    notifyListeners();
  }
}