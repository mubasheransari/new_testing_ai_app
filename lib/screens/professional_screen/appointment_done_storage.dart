import 'package:get_storage/get_storage.dart';

class AppointmentDoneStorage {
  static final GetStorage _box = GetStorage(); // ✅ not const

  static const _key = 'appointment_done_map'; // Map<String,bool>

  static Map<String, dynamic> _readMap() {
    final raw = _box.read(_key);
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  static bool isDone(int appointmentId) {
    final map = _readMap();
    return (map['$appointmentId'] == true);
  }

  static Future<void> setDone(int appointmentId, bool done) async {
    final map = _readMap();
    map['$appointmentId'] = done;
    await _box.write(_key, map);
  }
}
