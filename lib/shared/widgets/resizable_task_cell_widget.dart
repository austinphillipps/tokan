import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../features/calendar/widgets/calendar_task_widget.dart';
import '../../main.dart'; // Pour AppColors

/// Widget interactif pour redimensionner et déplacer une tâche dans le calendrier.
/// Gère le redimensionnement par le haut/bas et le déplacement vertical.
class ResizableTaskCell extends StatefulWidget {
  final CalendarTask task;
  final double top;
  final double height;
  final double availableWidth;
  final double leftOffset;
  final int column;
  final int totalColumns;
  final double cellHeight;
  final double maxHeight;
  final Function(CalendarTask updatedTask) onTaskResized;
  final Function(CalendarTask task) onTap;
  final DateTime? minAllowedStart;
  final DateTime? maxAllowedEnd;

  const ResizableTaskCell({
    Key? key,
    required this.task,
    required this.top,
    required this.height,
    required this.availableWidth,
    required this.leftOffset,
    required this.column,
    required this.totalColumns,
    required this.cellHeight,
    required this.maxHeight,
    required this.onTaskResized,
    required this.onTap,
    this.minAllowedStart,
    this.maxAllowedEnd,
  }) : super(key: key);

  @override
  _ResizableTaskCellState createState() => _ResizableTaskCellState();
}

class _ResizableTaskCellState extends State<ResizableTaskCell> {
  static const double _handleHeight = 12.0;
  static const int _snapGrid = 15;     // minutes
  static const int _minDuration = 30;  // minutes

  late double _top, _height;
  late DateTime _startTime, _endTime;

  String? _dragSide;
  bool _isDraggingVertically = false;
  bool _isDragging = false;
  double _dragDelta = 0.0;
  late double _baseTop, _baseHeight;
  late DateTime _baseStartTime, _baseEndTime;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant ResizableTaskCell old) {
    super.didUpdateWidget(old);
    if (widget.task.start != old.task.start ||
        widget.task.end != old.task.end ||
        widget.top != old.top ||
        widget.height != old.height) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    _top = widget.top;
    _height = widget.height;
    _startTime = widget.task.start;
    _endTime = widget.task.end;
  }

  /// Arrondit à l’intervalle de grille (_snapGrid minutes).
  DateTime _roundToGrid(DateTime dt) {
    final snap = (dt.minute / _snapGrid).round() * _snapGrid;
    final h = dt.hour + (snap >= 60 ? 1 : 0);
    final m = snap >= 60 ? 0 : snap;
    return DateTime(dt.year, dt.month, dt.day, h, m);
  }

  /// Renvoie le delta en minutes arrondi à la grille.
  int _snapDelta(double rawMinutes) =>
      (rawMinutes / _snapGrid).round() * _snapGrid;

  /// Contraint une DateTime entre minAllowedStart et maxAllowedEnd.
  DateTime _clamp(DateTime dt) {
    var c = dt;
    if (widget.minAllowedStart != null && c.isBefore(widget.minAllowedStart!)) {
      c = _roundToGrid(widget.minAllowedStart!);
    }
    if (widget.maxAllowedEnd != null && c.isAfter(widget.maxAllowedEnd!)) {
      c = _roundToGrid(widget.maxAllowedEnd!);
    }
    return c;
  }

  /// Mise à jour en cours de drag (redimensionnement ou déplacement vertical).
  void _updateDrag() {
    final snappedMinutes = _snapDelta(_dragDelta / widget.cellHeight * 60);

    if (_dragSide == 'top') {
      // Redimensionnement par le haut
      var newStart = _baseStartTime.add(Duration(minutes: snappedMinutes));
      newStart = _clamp(_roundToGrid(newStart));
      if (_baseEndTime.difference(newStart).inMinutes < _minDuration) {
        newStart = _roundToGrid(
          _baseEndTime.subtract(const Duration(minutes: _minDuration)),
        );
      }
      final deltaHeight = newStart.difference(_baseStartTime).inMinutes /
          60 *
          widget.cellHeight;
      if (!mounted) return;
      setState(() {
        _startTime = newStart;
        _height = _baseHeight - deltaHeight;
        _top = _baseTop + deltaHeight;
      });
    } else if (_dragSide == 'bottom') {
      // Redimensionnement par le bas
      var newEnd = _baseEndTime.add(Duration(minutes: snappedMinutes));
      newEnd = _clamp(_roundToGrid(newEnd));
      if (newEnd.difference(_baseStartTime).inMinutes < _minDuration) {
        newEnd = _roundToGrid(
          _baseStartTime.add(const Duration(minutes: _minDuration)),
        );
      }
      final deltaHeight = newEnd.difference(_baseEndTime).inMinutes /
          60 *
          widget.cellHeight;
      if (!mounted) return;
      setState(() {
        _endTime = newEnd;
        _height = _baseHeight + deltaHeight;
      });
    } else if (_isDraggingVertically) {
      // Déplacement vertical de la tâche
      final durationMins = _baseEndTime.difference(_baseStartTime).inMinutes;
      var newStart = _baseStartTime.add(Duration(minutes: snappedMinutes));
      newStart = _clamp(_roundToGrid(newStart));

      final maxStart =
      widget.maxAllowedEnd?.subtract(Duration(minutes: durationMins));
      if (maxStart != null && newStart.isAfter(maxStart)) {
        newStart = _roundToGrid(maxStart);
      }

      var newEnd = newStart.add(Duration(minutes: durationMins));
      newEnd = _clamp(_roundToGrid(newEnd));

      if (widget.maxAllowedEnd != null && newEnd.isAfter(widget.maxAllowedEnd!)) {
        newEnd = _roundToGrid(widget.maxAllowedEnd!);
        newStart = newEnd.subtract(Duration(minutes: durationMins));
      }

      final deltaTop = newStart.difference(_baseStartTime).inMinutes /
          60 *
          widget.cellHeight;
      if (!mounted) return;
      setState(() {
        _startTime = newStart;
        _endTime = newEnd;
        _top = _baseTop + deltaTop;
      });
    }

    // Contraintes visuelles : ne pas sortir du conteneur
    if (_top < 0) {
      _top = 0;
      _startTime =
          DateTime(_startTime.year, _startTime.month, _startTime.day, 0, 0);
      _height = widget.maxHeight;
    }
    final bottom = _top + _height;
    if (bottom > widget.maxHeight) {
      _height = widget.maxHeight - _top;
      final endMinutes = (bottom / widget.cellHeight * 60).round();
      _endTime = DateTime(
        _endTime.year,
        _endTime.month,
        _endTime.day,
        endMinutes ~/ 60,
        endMinutes % 60,
      );
    }
    if (_height < widget.cellHeight / 2) {
      _height = widget.cellHeight / 2;
      final endMinutes = _startTime.hour * 60 +
          _startTime.minute +
          _minDuration;
      _endTime = DateTime(
        _startTime.year,
        _startTime.month,
        _startTime.day,
        endMinutes ~/ 60,
        endMinutes % 60,
      );
    }
  }

  /// Informe le parent que le drag (redimensionnement ou déplacement) est terminé.
  void _notifyParentEndDrag() {
    widget.onTaskResized(
      CalendarTask(
        id: widget.task.id,
        start: _startTime,
        end: _endTime,
        title: widget.task.title,
        projectColor: widget.task.projectColor,
      ),
    );
  }

  void _onResizeStart(String side) {
    if (!mounted) return;
    setState(() {
      _dragSide = side;
      _dragDelta = 0;
      _baseTop = _top;
      _baseHeight = _height;
      _baseStartTime = _roundToGrid(_startTime);
      _baseEndTime = _roundToGrid(_endTime);
    });
  }

  Widget _buildCell({bool shadow = false}) {
    final isResizing = _dragSide != null;

    // Couleur du projet ou fallback
    final bgColor = widget.task.projectColor ?? AppColors.blue;

    return GestureDetector(
      onDoubleTap: () {
        // Double-tap réinitialise à 0h15
        if (!mounted) return;
        setState(() {
          _startTime =
              DateTime(_startTime.year, _startTime.month, _startTime.day, 0, 0);
          _endTime = _startTime.add(const Duration(minutes: _snapGrid));
        });
        _notifyParentEndDrag();
      },
      child: AnimatedContainer(
        duration: (_dragSide != null || _isDraggingVertically)
            ? Duration.zero
            : const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: widget.availableWidth,
        height: _height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isResizing ? Colors.orangeAccent : Colors.transparent,
            width: 2,
          ),
          boxShadow: shadow
              ? [const BoxShadow(color: Colors.black45, blurRadius: 12)]
              : [const BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Stack(
          children: [
            // Contenu principal : titre + plage horaire
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => widget.onTap(widget.task),
                onVerticalDragStart: (_) {
                  if (!mounted) return;
                  setState(() {
                    _isDraggingVertically = true;
                    _dragSide = null;
                    _dragDelta = 0;
                    _baseTop = _top;
                    _baseHeight = _height;
                    _baseStartTime = _roundToGrid(_startTime);
                    _baseEndTime = _roundToGrid(_endTime);
                  });
                },
                onVerticalDragUpdate: (d) {
                  HapticFeedback.selectionClick();
                  _dragDelta += d.delta.dy;
                  _updateDrag();
                },
                onVerticalDragEnd: (_) {
                  _notifyParentEndDrag();
                  if (!mounted) return;
                  setState(() => _isDraggingVertically = false);
                },
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Wrap(
                    spacing: 8.0,   // espace horizontal
                    runSpacing: 4.0, // espace vertical quand ça wrap
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        toBeginningOfSentenceCase(widget.task.title) ??
                            widget.task.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${DateFormat.Hm().format(_roundToGrid(_startTime))} - "
                            "${DateFormat.Hm().format(_roundToGrid(_endTime))}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Poignées de redimensionnement (haut et bas)
            for (var side in ['top', 'bottom'])
              Positioned(
                top: side == 'top' ? 0 : null,
                bottom: side == 'bottom' ? 0 : null,
                left: 0,
                right: 0,
                height: _handleHeight + 4,
                child: MouseRegion(
                  cursor: side == 'top'
                      ? SystemMouseCursors.resizeUp
                      : SystemMouseCursors.resizeDown,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: (_) => _onResizeStart(side),
                    onPanUpdate: (d) {
                      HapticFeedback.selectionClick();
                      _dragDelta += d.delta.dy;
                      _updateDrag();
                    },
                    onPanEnd: (_) {
                      _notifyParentEndDrag();
                      if (!mounted) return;
                      setState(() => _dragSide = null);
                    },
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _top,
      left: widget.leftOffset,
      child: LongPressDraggable<CalendarTask>(
        data: widget.task,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(opacity: 0.7, child: _buildCell(shadow: true)),
        ),
        childWhenDragging: Opacity(opacity: 0.2, child: _buildCell()),
        onDragStarted: () {
          if (!mounted) return;
          setState(() => _isDragging = true);
        },
        onDragUpdate: (details) {
          // Gère un éventuel scroll auto (non implémenté ici)
          _autoScrollIfNeeded(context, details.globalPosition);
        },
        onDragEnd: (_) {
          if (!mounted) return;
          setState(() => _isDragging = false);
        },
        onDraggableCanceled: (_, __) {
          if (!mounted) return;
          setState(() => _isDragging = false);
        },
        onDragCompleted: () {
          if (!mounted) return;
          setState(() => _isDragging = false);
        },
        child: MouseRegion(cursor: SystemMouseCursors.grab, child: _buildCell()),
      ),
    );
  }

  /// Placeholder pour scroll automatique si nécessaire (non implémenté).
  void _autoScrollIfNeeded(BuildContext ctx, Offset global) {
    // Par défaut, on n'implémente pas de scroll auto.
  }
}