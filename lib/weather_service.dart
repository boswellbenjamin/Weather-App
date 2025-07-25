import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const String forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast';
  static const String oneCallUrl = 'https://api.openweathermap.org/data/2.5/onecall';
  
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

  static Future<Map<String, dynamic>> getDetailedWeatherByCity(String cityName) async {
    try {
      final apiKey = dotenv.env['WEATHER_API_KEY'];
      
      if (apiKey == null) {
        throw Exception('API key not found');
      }

      // Get basic weather data first
      final basicUrl = '$baseUrl?q=$cityName&appid=$apiKey&units=metric';
      final basicResponse = await http.get(Uri.parse(basicUrl));
      
      if (basicResponse.statusCode != 200) {
        throw Exception('Failed to load weather data for $cityName: ${basicResponse.statusCode}\nResponse: ${basicResponse.body}');
      }
      
      final basicData = json.decode(basicResponse.body);
      final lat = basicData['coord']['lat'];
      final lon = basicData['coord']['lon'];
      
      // Try to get detailed weather data using One Call API
      try {
        final detailedUrl = '$oneCallUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric&exclude=minutely,alerts';
        final detailedResponse = await http.get(Uri.parse(detailedUrl));
        
        if (detailedResponse.statusCode == 200) {
          final detailedData = json.decode(detailedResponse.body);
          // Combine basic city info with detailed weather data
          detailedData['name'] = basicData['name'];
          detailedData['country'] = basicData['sys']['country'];
          return detailedData;
        } else {
          print('One Call API failed: ${detailedResponse.statusCode} - ${detailedResponse.body}');
          // Fallback to enhanced basic data
          return _enhanceBasicWeatherData(basicData);
        }
      } catch (e) {
        print('One Call API error: $e');
        // Fallback to enhanced basic data
        return _enhanceBasicWeatherData(basicData);
      }
    } catch (e) {
      throw Exception('Error getting weather for $cityName: $e');
    }
  }

  static Map<String, dynamic> _enhanceBasicWeatherData(Map<String, dynamic> basicData) {
    // Create a structure similar to One Call API for compatibility
    return {
      'name': basicData['name'],
      'country': basicData['sys']['country'],
      'current': {
        'temp': basicData['main']['temp'],
        'feels_like': basicData['main']['feels_like'],
        'humidity': basicData['main']['humidity'],
        'pressure': basicData['main']['pressure'],
        'visibility': basicData['visibility'] ?? 10000,
        'wind_speed': basicData['wind']['speed'] ?? 0,
        'wind_deg': basicData['wind']['deg'] ?? 0,
        'weather': basicData['weather'],
        'sunrise': basicData['sys']['sunrise'],
        'sunset': basicData['sys']['sunset'],
        'uvi': 0, // Default value since basic API doesn't provide UV index
      },
      'timezone': basicData['timezone'] ?? 0,
    };
  }

  static Future<Map<String, dynamic>> getDetailedWeatherByLocation() async {
    try {
      final position = await getCurrentLocation();
      final apiKey = dotenv.env['WEATHER_API_KEY'];
      
      if (apiKey == null) {
        throw Exception('API key not found');
      }

      // Get basic weather data first
      final basicUrl = '$baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric';
      final basicResponse = await http.get(Uri.parse(basicUrl));
      
      if (basicResponse.statusCode != 200) {
        throw Exception('Failed to load weather data: ${basicResponse.statusCode}');
      }
      
      final basicData = json.decode(basicResponse.body);

      // Try to get detailed weather data using One Call API
      try {
        final detailedUrl = '$oneCallUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric&exclude=minutely,alerts';
        final detailedResponse = await http.get(Uri.parse(detailedUrl));
        
        if (detailedResponse.statusCode == 200) {
          final detailedData = json.decode(detailedResponse.body);
          detailedData['name'] = basicData['name'];
          detailedData['country'] = basicData['sys']['country'];
          return detailedData;
        } else {
          print('One Call API failed: ${detailedResponse.statusCode} - ${detailedResponse.body}');
          return _enhanceBasicWeatherData(basicData);
        }
      } catch (e) {
        print('One Call API error: $e');
        return _enhanceBasicWeatherData(basicData);
      }
    } catch (e) {
      throw Exception('Error getting weather by location: $e');
    }
  }
}