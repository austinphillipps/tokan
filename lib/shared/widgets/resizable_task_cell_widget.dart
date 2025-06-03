import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../features/calendar/widgets/calendar_task_widget.dart';

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
  static const int _snapGrid = 15;     // min
  static const int _minDuration = 30;  // min

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

  DateTime _roundToGrid(DateTime dt) {
    final snap = (dt.minute / _snapGrid).round() * _snapGrid;
    final h = dt.hour + (snap >= 60 ? 1 : 0);
    final m = snap >= 60 ? 0 : snap;
    return DateTime(dt.year, dt.month, dt.day, h, m);
  }

  int _snapDelta(double rawMinutes) =>
      (rawMinutes / _snapGrid).round() * _snapGrid;

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

  void _updateDrag() {
    final snapped = _snapDelta(_dragDelta / widget.cellHeight * 60);
    if (_dragSide == 'top') {
      var ns = _baseStartTime.add(Duration(minutes: snapped));
      ns = _clamp(_roundToGrid(ns));
      if (_baseEndTime.difference(ns).inMinutes < _minDuration) {
        ns = _roundToGrid(
            _baseEndTime.subtract(const Duration(minutes: _minDuration)));
      }
      final dH = ns.difference(_baseStartTime).inMinutes / 60 * widget.cellHeight;
      setState(() {
        _startTime = ns;
        _height = _baseHeight - dH;
        _top = _baseTop + dH;
      });
    } else if (_dragSide == 'bottom') {
      var ne = _baseEndTime.add(Duration(minutes: snapped));
      ne = _clamp(_roundToGrid(ne));
      if (ne.difference(_baseStartTime).inMinutes < _minDuration) {
        ne = _roundToGrid(
            _baseStartTime.add(const Duration(minutes: _minDuration)));
      }
      final dH = ne.difference(_baseEndTime).inMinutes / 60 * widget.cellHeight;
      setState(() {
        _endTime = ne;
        _height = _baseHeight + dH;
      });
    } else if (_isDraggingVertically) {
      final dur = _baseEndTime.difference(_baseStartTime).inMinutes;
      var ns = _baseStartTime.add(Duration(minutes: snapped));
      ns = _clamp(_roundToGrid(ns));
      final maxS = widget.maxAllowedEnd?.subtract(Duration(minutes: dur));
      if (maxS != null && ns.isAfter(maxS)) ns = _roundToGrid(maxS);
      var ne = ns.add(Duration(minutes: dur));
      ne = _clamp(_roundToGrid(ne));
      if (widget.maxAllowedEnd != null && ne.isAfter(widget.maxAllowedEnd!)) {
        ne = _roundToGrid(widget.maxAllowedEnd!);
        ns = ne.subtract(Duration(minutes: dur));
      }
      final dH = ns.difference(_baseStartTime).inMinutes / 60 * widget.cellHeight;
      setState(() {
        _startTime = ns;
        _endTime = ne;
        _top = _baseTop + dH;
      });
    }

    if (_top < 0) {
      _top = 0;
      _startTime = DateTime(_startTime.year, _startTime.month, _startTime.day, 0, 0);
      _height = widget.maxHeight;
    }
    final bottom = _top + _height;
    if (bottom > widget.maxHeight) {
      _height = widget.maxHeight - _top;
      final em = (bottom / widget.cellHeight * 60).round();
      _endTime = DateTime(
          _endTime.year, _endTime.month, _endTime.day, em ~/ 60, em % 60);
    }
    if (_height < widget.cellHeight / 2) {
      _height = widget.cellHeight / 2;
      final em = _startTime.hour * 60 + _startTime.minute + _minDuration;
      _endTime = DateTime(_startTime.year, _startTime.month, _startTime.day,
          em ~/ 60, em % 60);
    }
  }

  void _notifyParentEndDrag() {
    widget.onTaskResized(
      CalendarTask(
        id: widget.task.id,
        start: _startTime,
        end: _endTime,
        title: widget.task.title,
        columnIndex: widget.column,
        totalColumns: widget.totalColumns,
        topPx: _top,
        heightPx: _height,
      ),
    );
  }

  void _onResizeStart(String side) {
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
    return GestureDetector(
      onDoubleTap: () {
        setState(() {
          _startTime = DateTime(_startTime.year, _startTime.month, _startTime.day, 0, 0);
          _endTime = _startTime.add(const Duration(minutes: _snapGrid));
        });
        _notifyParentEndDrag();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: widget.availableWidth,
        height: _height,
        decoration: BoxDecoration(
          color: Colors.blueAccent,
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
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => widget.onTap(widget.task),
                onVerticalDragStart: (_) {
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
                  setState(() => _isDraggingVertically = false);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Wrap(
                    spacing: 8.0,      // espace horizontal
                    runSpacing: 4.0,    // espace vertical quand ça wrap
                    alignment: WrapAlignment.spaceBetween,

                    children: [
                      Text(
                        toBeginningOfSentenceCase(widget.task.title) ?? widget.task.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${DateFormat.Hm().format(_roundToGrid(_startTime))} - ${DateFormat.Hm().format(_roundToGrid(_endTime))}",
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
        onDragStarted: () => setState(() => _isDragging = true),
        onDragUpdate: (d) => _autoScrollIfNeeded(context, d.globalPosition),
        onDragEnd: (_) => setState(() => _isDragging = false),
        onDraggableCanceled: (_, __) => setState(() => _isDragging = false),
        onDragCompleted: () => setState(() => _isDragging = false),
        child: MouseRegion(cursor: SystemMouseCursors.grab, child: _buildCell()),
      ),
    );
  }

  void _autoScrollIfNeeded(BuildContext ctx, Offset global) {}
}
