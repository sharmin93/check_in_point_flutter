import 'package:hive/hive.dart';

part 'check_in_entry.g.dart';

@HiveType(typeId: 2)
class CheckInEntry {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final DateTime time;

  CheckInEntry({
    required this.userId,
    required this.time,
  });
}
