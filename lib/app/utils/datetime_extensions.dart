extension DateTimeExtension on DateTime {
  DateTime toIST() {
    // Convert to UTC first to have a baseline, then add 5 hours 30 minutes
    return toUtc().add(const Duration(hours: 5, minutes: 30));
  }
}
