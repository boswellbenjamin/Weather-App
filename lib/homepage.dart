import 'package:flutter/material.dart';
import 'weather_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  String? errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await WeatherService.getWeatherByLocation();
      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadWeatherByCity(String cityName) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await WeatherService.getWeatherByCity(cityName);
      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search City'),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Enter city name...',
            prefixIcon: Icon(Icons.location_city),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.of(context).pop();
              _loadWeatherByCity(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final city = _searchController.text.trim();
              if (city.isNotEmpty) {
                Navigator.of(context).pop();
                _loadWeatherByCity(city);
                _searchController.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: Text('Search'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(221, 27, 27, 27),
      appBar: AppBar(
        title: Text(weatherData?['name'] ?? 'Weather App'),
        backgroundColor: const Color.fromARGB(221, 27, 27, 27),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _loadWeather,
            tooltip: 'Use my location',
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Search city',
          ),
        ],
      ),
      body: Center(
        child: isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.deepPurple),
                  SizedBox(height: 20),
                  Text(
                    'Getting your location...',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              )
            : errorMessage != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 100, color: Colors.red),
                  SizedBox(height: 20),
                  Text(
                    'Error',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadWeather,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Try Again'),
                  ),
                ],
              )
            : weatherData != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getWeatherIcon(weatherData!['weather'][0]['main']),
                    size: 100,
                    color: Colors.orange,
                  ),
                  SizedBox(height: 20),
                  Text(
                    '${weatherData!['main']['temp'].round()}°C',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    weatherData!['weather'][0]['description']
                        .toString()
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildWeatherDetail(
                        'Feels like',
                        '${weatherData!['main']['feels_like'].round()}°C',
                        Icons.thermostat,
                      ),
                      _buildWeatherDetail(
                        'Humidity',
                        '${weatherData!['main']['humidity']}%',
                        Icons.water_drop,
                      ),
                      _buildWeatherDetail(
                        'Wind',
                        '${weatherData!['wind']['speed']} m/s',
                        Icons.air,
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wb_sunny, size: 100, color: Colors.orange),
                  SizedBox(height: 20),
                  Text(
                    'Welcome to Weather App',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Ready to check the weather!',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 30),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.wb_cloudy;
      case 'rain':
        return Icons.umbrella;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'drizzle':
        return Icons.grain;
      case 'mist':
      case 'fog':
        return Icons.blur_on;
      default:
        return Icons.wb_sunny;
    }
  }
}
