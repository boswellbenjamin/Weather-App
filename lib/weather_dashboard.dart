import 'package:flutter/material.dart';
import 'weather_service.dart';
import 'dart:math' as math;

class WeatherDashboard extends StatefulWidget {
  final String cityName;
  
  const WeatherDashboard({super.key, required this.cityName});

  @override
  State<WeatherDashboard> createState() => _WeatherDashboardState();
}

class _WeatherDashboardState extends State<WeatherDashboard> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  String? errorMessage;
  int selectedDayIndex = 0;
  
  final List<String> days = ['Today', 'Tomorrow', 'Day 3', 'Day 4', 'Day 5'];

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await WeatherService.getDetailedWeatherByCity(widget.cityName);
      print('Weather data received: ${data.keys}');
      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Weather dashboard error: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  String _formatTime(int timestamp) {
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  String _getUVDescription(double uv) {
    if (uv <= 2) return 'Low';
    if (uv <= 5) return 'Moderate';
    if (uv <= 7) return 'High';
    if (uv <= 10) return 'Very High';
    return 'Extreme';
  }

  Color _getUVColor(double uv) {
    if (uv <= 2) return Colors.green;
    if (uv <= 5) return Colors.yellow;
    if (uv <= 7) return Colors.orange;
    if (uv <= 10) return Colors.red;
    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.deepPurple),
                    SizedBox(height: 20),
                    Text(
                      'Loading weather data...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 80, color: Colors.red),
                        SizedBox(height: 20),
                        Text(
                          'Error loading weather data',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _loadWeatherData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          child: Text('Try Again'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // App Bar
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    weatherData!['name'] ?? widget.cityName,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    weatherData!['country'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _loadWeatherData,
                              icon: Icon(Icons.refresh, color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                      // Day Selector
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Stack(
                          children: [
                            // Animated sliding pill background
                            AnimatedPositioned(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              left: selectedDayIndex * (MediaQuery.of(context).size.width - 48) / days.length,
                              child: Container(
                                width: (MediaQuery.of(context).size.width - 48) / days.length,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.deepPurple.shade400,
                                      Colors.deepPurple.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            // Day buttons
                            Row(
                              children: days.asMap().entries.map((entry) {
                                int index = entry.key;
                                String day = entry.value;
                                bool isSelected = selectedDayIndex == index;
                                
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedDayIndex = index;
                                      });
                                    },
                                    child: Container(
                                      height: 40,
                                      alignment: Alignment.center,
                                      child: Text(
                                        day,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.white70,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      // Main Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              // Main Weather Card
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.deepPurple.shade400,
                                      Colors.deepPurple.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      _getWeatherIcon(weatherData!['current']['weather'][0]['main']),
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      '${weatherData!['current']['temp'].round()}°',
                                      style: TextStyle(
                                        fontSize: 64,
                                        fontWeight: FontWeight.w200,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      weatherData!['current']['weather'][0]['description'].toString().toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              'Feels like',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            Text(
                                              '${weatherData!['current']['feels_like'].round()}°',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              'Humidity',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            Text(
                                              '${weatherData!['current']['humidity']}%',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 20),

                              // Weather Details Grid
                              GridView.count(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                childAspectRatio: 1.2,
                                children: [
                                  // UV Index
                                  _buildWeatherCard(
                                    'UV Index',
                                    '${weatherData!['current']['uvi']?.toStringAsFixed(1) ?? 'N/A'}',
                                    _getUVDescription(weatherData!['current']['uvi']?.toDouble() ?? 0),
                                    Icons.wb_sunny,
                                    _getUVColor(weatherData!['current']['uvi']?.toDouble() ?? 0),
                                  ),
                                  
                                  // Wind Speed
                                  _buildWeatherCard(
                                    'Wind',
                                    '${weatherData!['current']['wind_speed']?.toStringAsFixed(1) ?? 'N/A'} m/s',
                                    '${weatherData!['current']['wind_deg']?.round() ?? 0}°',
                                    Icons.air,
                                    Colors.blue,
                                  ),
                                  
                                  // Pressure
                                  _buildWeatherCard(
                                    'Pressure',
                                    '${weatherData!['current']['pressure'] ?? 'N/A'}',
                                    'hPa',
                                    Icons.speed,
                                    Colors.orange,
                                  ),
                                  
                                  // Visibility
                                  _buildWeatherCard(
                                    'Visibility',
                                    '${((weatherData!['current']['visibility'] ?? 0) / 1000).toStringAsFixed(1)}',
                                    'km',
                                    Icons.visibility,
                                    Colors.teal,
                                  ),
                                ],
                              ),

                              SizedBox(height: 20),

                              // Sunrise & Sunset
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sun & Moon',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.wb_sunny,
                                                color: Colors.orange,
                                                size: 32,
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Sunrise',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              Text(
                                                _formatTime(weatherData!['current']['sunrise']),
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          height: 60,
                                          width: 1,
                                          color: Colors.grey[700],
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.brightness_2,
                                                color: Colors.indigo.shade300,
                                                size: 32,
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Sunset',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              Text(
                                                _formatTime(weatherData!['current']['sunset']),
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildWeatherCard(String title, String value, String subtitle, IconData icon, Color iconColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}