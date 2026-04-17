import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationWeatherResult {
  final String location;
  final String weather;

  LocationWeatherResult({required this.location, required this.weather});
}

class LocationWeatherService {
  
  // 1) GPS İzninin kontrol edilmesi
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('LOCATION_SERVICE_DISABLED');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('PERMISSION_DENIED_FOREVER');
    }

    return true;
  }

  // Ana metot: Hem konumu bulur hem metne/havaya çevirir
  Future<LocationWeatherResult?> fetchCurrentData() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return null;

    try {
      // Koordinatları al
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      // Adresi çek (Nominatim API - tamamen ücretsiz ve key istemez)
      final locationString = await _getCityFromCoordinates(
        position.latitude, 
        position.longitude,
      );

      // Hava durumunu çek (Open-Meteo API - ücretsiz ve key istemez)
      final weatherString = await _getWeatherFromCoordinates(
        position.latitude, 
        position.longitude,
      );

      if (locationString != null && weatherString != null) {
        return LocationWeatherResult(
          location: locationString,
          weather: weatherString,
        );
      }
      return null;
    } catch (e) {
      if (e.toString().contains('PERMISSION_DENIED_FOREVER') ||
          e.toString().contains('LOCATION_SERVICE_DISABLED')) {
        rethrow;
      }
      return null;
    }
  }

  Future<String?> _getCityFromCoordinates(double lat, double lon) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon');
    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'FlutterDiaryApp/1.0', // OpenStreetMap politikaları için gerekli
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        final city = address['city'] ?? address['town'] ?? address['village'] ?? address['county'];
        final country = address['country'];
        if (city != null) {
          return '$city, $country';
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _getWeatherFromCoordinates(double lat, double lon) async {
    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_weather'];
        final temperature = current['temperature'].round();
        final weatherCode = current['weathercode'];

        // WMO Weather interpretation codes
        String icon = '🌤️';
        if (weatherCode == 0) icon = '☀️'; // Açık
        else if (weatherCode == 1 || weatherCode == 2 || weatherCode == 3) icon = '⛅'; // Parçalı Bulutlu
        else if (weatherCode >= 45 && weatherCode <= 48) icon = '🌫️'; // Sisli
        else if (weatherCode >= 51 && weatherCode <= 67) icon = '🌧️'; // Yağmurlu
        else if (weatherCode >= 71 && weatherCode <= 77) icon = '❄️'; // Karlı
        else if (weatherCode >= 80 && weatherCode <= 82) icon = '🌦️'; // Sağanak Yağış
        else if (weatherCode >= 95) icon = '⛈️'; // Gök gürültülü

        return '$icon $temperature°C';
      }
    } catch (_) {}
    return null;
  }
}

// Global Provider
final locationWeatherServiceProvider = Provider((ref) => LocationWeatherService());
