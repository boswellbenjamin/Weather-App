import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static const String currentWeatherUrl =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String forecastUrl =
      'https://api.openweathermap.org/data/2.5/forecast';
  static const String hourlyForecastUrl =
      'https://pro.openweathermap.org/data/2.5/forecast/hourly';
  static const String dailyForecastUrl =
      'https://api.openweathermap.org/data/2.5/forecast/daily';

  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable location services in your device settings.',
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied. Please enable location access in your device settings.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    );
  }

  static Future<Map<String, dynamic>> getWeatherByLocation() async {
    try {
      final position = await getCurrentLocation();
      return await _fetchWeatherData(
        lat: position.latitude,
        lon: position.longitude,
      );
    } catch (e) {
      throw Exception('Error getting weather by location: $e');
    }
  }

  static Future<Map<String, dynamic>> getWeatherByCity(String cityName) async {
    try {
      final apiKey = dotenv.env['WEATHER_API_KEY'];
      if (apiKey == null) throw Exception('API key not found');

      // First get city coordinates
      final geoUrl =
          'http://api.openweathermap.org/geo/1.0/direct?q=$cityName&limit=1&appid=$apiKey';
      final geoResponse = await http.get(Uri.parse(geoUrl));

      if (geoResponse.statusCode != 200) {
        throw Exception('Failed to find city: $cityName');
      }

      final geoData = json.decode(geoResponse.body) as List;
      if (geoData.isEmpty) {
        throw Exception('City not found: $cityName');
      }

      final lat = geoData[0]['lat'];
      final lon = geoData[0]['lon'];
      final cityDisplayName = geoData[0]['name'];
      final country = geoData[0]['country'];

      final weatherData = await _fetchWeatherData(lat: lat, lon: lon);
      weatherData['name'] = cityDisplayName;
      weatherData['country'] = country;

      return weatherData;
    } catch (e) {
      throw Exception('Error getting weather for $cityName: $e');
    }
  }

  static Future<Map<String, dynamic>> getDetailedWeatherByCity(
    String cityName,
  ) async {
    return await getWeatherByCity(cityName);
  }

  static Future<Map<String, dynamic>> getDetailedWeatherByLocation() async {
    return await getWeatherByLocation();
  }

  static Future<Map<String, dynamic>> _fetchWeatherData({
    required double lat,
    required double lon,
  }) async {
    try {
      final apiKey = dotenv.env['WEATHER_API_KEY'];
      if (apiKey == null) throw Exception('API key not found');

      // Fetch current weather
      final currentUrl =
          '$currentWeatherUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
      final currentResponse = await http.get(Uri.parse(currentUrl));

      if (currentResponse.statusCode != 200) {
        throw Exception(
          'Failed to fetch current weather: ${currentResponse.statusCode}',
        );
      }

      final currentData = json.decode(currentResponse.body);

      // Try hourly forecast first (Pro API), fall back to 3-hour intervals
      Map<String, dynamic>? hourlyForecastData;
      Map<String, dynamic>? standardForecastData;

      // Try hourly forecast API (Student/Pro subscription)
      try {
        final hourlyApiUrl =
            '$hourlyForecastUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
        print('Trying hourly API: $hourlyApiUrl');
        final hourlyResponse = await http.get(Uri.parse(hourlyApiUrl));

        print('Hourly API response status: ${hourlyResponse.statusCode}');
        if (hourlyResponse.statusCode == 200) {
          hourlyForecastData = json.decode(hourlyResponse.body);
          print('Successfully got hourly forecast data');
        } else {
          print('Hourly API failed with status: ${hourlyResponse.statusCode}');
          print('Response body: ${hourlyResponse.body}');
        }
      } catch (e) {
        print('Hourly API error: $e');
      }

      // Fetch 5-day forecast (3-hour intervals) as fallback
      final forecastApiUrl =
          '$forecastUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
      final forecastResponse = await http.get(Uri.parse(forecastApiUrl));


      if (forecastResponse.statusCode != 200) {
        throw Exception(
          'Failed to fetch forecast: ${forecastResponse.statusCode}',
        );
      }

      standardForecastData = json.decode(forecastResponse.body);

      // Process forecast data - use hourly if available, otherwise 3-hour intervals
      List<Map<String, dynamic>> hourlyData;
      List<Map<String, dynamic>> dailyData;

      if (hourlyForecastData != null && hourlyForecastData['list'] != null) {
        // Use true hourly data
        print('=== Using Hourly Forecast API ===');
        print('First 12 hourly items:');
        for (int i = 0; i < 12 && i < hourlyForecastData['list'].length; i++) {
          final item = hourlyForecastData['list'][i];
          final time = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final temp = item['main']?['temp'] ?? item['temp'] ?? 'unknown';
          print(
            '  ${time.hour}:00 - ${temp}°C (${item['dt_txt'] ?? 'no time text'})',
          );
        }
        hourlyData = _processHourlyForecastPro(hourlyForecastData['list']);
        dailyData = _processDailyForecast(standardForecastData!['list']);
      } else {
        // Use 3-hour interval data
        print('=== Using 3-Hour Forecast API ===');
        print('First few 3-hour items:');
        for (
          int i = 0;
          i < 5 && i < standardForecastData!['list'].length;
          i++
        ) {
          final item = standardForecastData!['list'][i];
          final time = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final temp = item['main']['temp'];
          print('  ${time.hour}:00 - ${temp}°C (${item['dt_txt']})');
        }
        hourlyData = _processHourlyForecast(standardForecastData!['list']);
        dailyData = _processDailyForecast(standardForecastData!['list']);
      }

      // Process and structure the data
      return {
        'name': currentData['name'],
        'country': currentData['sys']['country'],
        'current': {
          'temp': currentData['main']['temp'].toDouble(),
          'feels_like': currentData['main']['feels_like'].toDouble(),
          'humidity': currentData['main']['humidity'],
          'pressure': currentData['main']['pressure'],
          'wind_speed': (currentData['wind']['speed'] ?? 0).toDouble(),
          'wind_deg': currentData['wind']['deg'] ?? 0,
          'weather': {
            ...currentData['weather'][0],
            'description': _simplifyWeatherDescription(currentData['weather'][0]['description']),
          },
          'sunrise': currentData['sys']['sunrise'],
          'sunset': currentData['sys']['sunset'],
        },
        'hourly': hourlyData,
        'daily': dailyData,
        'timezone': currentData['timezone'] ?? 0,
      };
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  static List<Map<String, dynamic>> _processHourlyForecast(
    List<dynamic> forecastList,
  ) {
    // Take next 8 intervals (24 hours in 3-hour chunks)
    final now = DateTime.now();

    return forecastList.take(8).map<Map<String, dynamic>>((item) {
      final forecastTime = DateTime.fromMillisecondsSinceEpoch(
        item['dt'] * 1000,
      );

      return {
        'dt': item['dt'],
        'temp': item['main']['temp'].toDouble(),
        'weather': {
          ...item['weather'][0],
          'description': _simplifyWeatherDescription(item['weather'][0]['description']),
        },
        'pop': ((item['pop'] ?? 0) * 100).round(),
        'wind_speed': (item['wind']['speed'] ?? 0).toDouble(),
        'hour': forecastTime.hour,
        'isNow': forecastTime.difference(now).inHours.abs() < 2,
        'isThreeHourInterval': true, // Flag to indicate this is 3-hour data
      };
    }).toList();
  }

  // Process hourly forecast API data (student/pro account - true hourly intervals)
  static List<Map<String, dynamic>> _processHourlyForecastPro(
    List<dynamic> hourlyList,
  ) {
    final now = DateTime.now();

    return hourlyList.take(24).map<Map<String, dynamic>>((item) {
      final forecastTime = DateTime.fromMillisecondsSinceEpoch(
        item['dt'] * 1000,
      );

      // Handle both possible response structures
      double temp;
      Map<String, dynamic> weather;
      double windSpeed;

      if (item['main'] != null) {
        // Standard structure with 'main' object
        temp = item['main']['temp'].toDouble();
        weather = item['weather'][0];
        windSpeed = (item['wind']['speed'] ?? 0).toDouble();
      } else {
        // Direct structure (some student API responses)
        temp = (item['temp'] ?? item['temperature'] ?? 0).toDouble();
        weather = item['weather'][0];
        windSpeed = (item['wind_speed'] ?? item['wind']['speed'] ?? 0)
            .toDouble();
      }

      return {
        'dt': item['dt'],
        'temp': temp,
        'weather': {
          ...weather,
          'description': _simplifyWeatherDescription(weather['description']),
        },
        'pop': ((item['pop'] ?? 0) * 100).round(),
        'wind_speed': windSpeed,
        'hour': forecastTime.hour,
        'isNow': forecastTime.difference(now).inMinutes.abs() < 90,
        'isThreeHourInterval': false, // True hourly data
      };
    }).toList();
  }

  static String _simplifyWeatherDescription(String description) {
    final lowerDesc = description.toLowerCase();
    
    // Map complex weather terms to simpler ones
    if (lowerDesc.contains('squall')) {
      return lowerDesc.replaceAll('squalls', 'strong gusty winds')
                     .replaceAll('squall', 'strong gusty winds');
    }
    if (lowerDesc.contains('drizzle')) {
      return lowerDesc.replaceAll('drizzle', 'light rain');
    }
    if (lowerDesc.contains('shower')) {
      return lowerDesc.replaceAll('shower', 'rain');
    }
    if (lowerDesc.contains('mist')) {
      return lowerDesc.replaceAll('mist', 'light fog');
    }
    if (lowerDesc.contains('haze')) {
      return lowerDesc.replaceAll('haze', 'light fog');
    }
    if (lowerDesc.contains('overcast')) {
      return lowerDesc.replaceAll('overcast', 'very cloudy');
    }
    if (lowerDesc.contains('broken clouds')) {
      return lowerDesc.replaceAll('broken clouds', 'mostly cloudy');
    }
    if (lowerDesc.contains('scattered clouds')) {
      return lowerDesc.replaceAll('scattered clouds', 'partly cloudy');
    }
    if (lowerDesc.contains('few clouds')) {
      return lowerDesc.replaceAll('few clouds', 'mostly sunny');
    }
    if (lowerDesc.contains('clear sky')) {
      return lowerDesc.replaceAll('clear sky', 'sunny');
    }
    
    return description; // Return original if no simplification needed
  }

  static List<Map<String, dynamic>> _processDailyForecast(
    List<dynamic> forecastList,
  ) {
    // Group by date (not including time)
    final Map<String, List<dynamic>> dailyGroups = {};

    for (var item in forecastList) {
      final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      dailyGroups.putIfAbsent(dateKey, () => []).add(item);
    }

    // Process up to 5 days, starting from today
    final sortedDays = dailyGroups.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sortedDays.take(5).map<Map<String, dynamic>>((entry) {
      final dayItems = entry.value;
      // Extract all temperatures from main.temp for accurate min/max
      final temps = dayItems
          .map<double>((item) => item['main']['temp'].toDouble())
          .toList();

      // Choose weather condition from the middle of the day (around noon)
      var representativeItem = dayItems.first;
      for (var item in dayItems) {
        final itemTime = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
        if (itemTime.hour >= 12 && itemTime.hour <= 15) {
          representativeItem = item;
          break;
        }
      }

      // Calculate average precipitation probability
      final avgPop = dayItems.isEmpty
          ? 0.0
          : dayItems.map((item) => item['pop'] ?? 0.0).reduce((a, b) => a + b) /
                dayItems.length;

      return {
        'dt': dayItems.first['dt'],
        'temp': {
          'min': temps.reduce(
            (a, b) => a < b ? a : b,
          ), // Minimum temp from main.temp
          'max': temps.reduce(
            (a, b) => a > b ? a : b,
          ), // Maximum temp from main.temp
        },
        'weather': {
          ...representativeItem['weather'][0],
          'description': _simplifyWeatherDescription(representativeItem['weather'][0]['description']),
        },
        'pop': (avgPop * 100).round(),
      };
    }).toList();
  }
}
