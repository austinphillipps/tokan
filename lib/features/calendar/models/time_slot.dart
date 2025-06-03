class TimeSlot {
  final String timeRange;
  String? task;
  bool completed;

  TimeSlot({
    required this.timeRange,
    this.task,
    this.completed = false,
  });
}
