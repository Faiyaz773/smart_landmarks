import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Requests permission (if needed) and returns the current position.
  /// Throws a plain string message on failure so UI can show it directly.
  static Future<Position> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'Location services are disabled. Please enable GPS.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied. Enable it in Settings.';
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}
