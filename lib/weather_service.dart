import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable location services in your device settings.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable location access in your device settings.');
    }

    // Request high accuracy location with timeout
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    );
  }

  static Future<Map<String, dynamic>> getWeatherByLocation() async {
    try {
      final position = await getCurrentLocation();
      final apiKey = dotenv.env['WEATHER_API_KEY'];
      
      if (apiKey == null) {
        throw Exception('API key not found');
      }

      final url = '$baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting weather: $e');
    }
  }

  static Future<Map<String, dynamic>> getWeatherByCity(String cityName) async {
    try {
      final apiKey = dotenv.env['WEATHER_API_KEY'];
      
      if (apiKey == null) {
        throw Exception('API key not found');
      }

      final url = '$baseUrl?q=$cityName&appid=$apiKey&units=metric';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting weather: $e');
    }
  }
}