import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'weather_service.dart';
import 'weather_particles.dart';

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
      final data = await WeatherService.getDetailedWeatherByCity(
        widget.cityName,
      );
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


  List<Color> _getWeatherGradient() {
    if (weatherData == null) return [Colors.black, Colors.grey.shade900];

    final weather = weatherData!['current']['weather'];
    final condition = weather['main'].toLowerCase();
    final isDay = _isDay();

    switch (condition) {
      case 'clear':
        return isDay
            ? [Color(0xFF4FC3F7), Color(0xFF29B6F6), Color(0xFF0277BD)]
            : [Color(0xFF1A237E), Color(0xFF303F9F), Color(0xFF3F51B5)];
      case 'clouds':
        return isDay
            ? [Color(0xFF78909C), Color(0xFF607D8B), Color(0xFF455A64)]
            : [Color(0xFF263238), Color(0xFF37474F), Color(0xFF455A64)];
      case 'rain':
      case 'drizzle':
        return [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF1E88E5)];
      case 'thunderstorm':
        return [Color(0xFF424242), Color(0xFF616161), Color(0xFF757575)];
      case 'snow':
        return [Color(0xFFCFD8DC), Color(0xFFB0BEC5), Color(0xFF90A4AE)];
      case 'mist':
      case 'fog':
        return [Color(0xFF546E7A), Color(0xFF607D8B), Color(0xFF78909C)];
      default:
        return isDay
            ? [Color(0xFF4A90E2), Color(0xFF357ABD), Color(0xFF1E3A8A)]
            : [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)];
    }
  }

  bool _isDay() {
    if (weatherData == null) return true;
    final now = DateTime.now();
    final sunrise = DateTime.fromMillisecondsSinceEpoch(
      weatherData!['current']['sunrise'] * 1000,
    );
    final sunset = DateTime.fromMillisecondsSinceEpoch(
      weatherData!['current']['sunset'] * 1000,
    );
    return now.isAfter(sunrise) && now.isBefore(sunset);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Colors.black],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.blue.shade400,
                  strokeWidth: 3,
                ),
                SizedBox(height: 24),
                Text(
                  'Loading weather data...',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Colors.black],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _loadWeatherData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(Icons.refresh),
                      label: Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final weatherCondition = weatherData!['current']['weather']['main'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: WeatherParticles(
        weatherCondition: weatherCondition,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _getWeatherGradient(),
            ),
          ),
          child: CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                elevation: 0,
                pinned: true,
                floating: false,
                snap: false,
                centerTitle: true,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    backgroundBlendMode: BlendMode.overlay,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                title: Column(
                  children: [
                    Text(
                      weatherData!['name'] ?? widget.cityName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      weatherData!['country'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    onPressed: _loadWeatherData,
                    icon: Icon(Icons.refresh_rounded),
                  ),
                ],
              ),

              // Main Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Weather Card - Full Width
                    _buildHeroWeatherCard(),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 32),

                          // Hourly Forecast
                          _buildSectionTitle(_getForecastTitle()),
                          SizedBox(height: 16),
                          _buildHourlyForecast(),

                          SizedBox(height: 32),

                          // Weather Details Grid
                          _buildSectionTitle('Weather Details'),
                          SizedBox(height: 16),
                          _buildWeatherDetailsGrid(),

                          SizedBox(height: 32),

                          // 5-Day Forecast
                          _buildSectionTitle('5-Day Forecast'),
                          SizedBox(height: 16),
                          _buildDailyForecast(),

                          SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroWeatherCard() {
    final current = weatherData!['current'];
    final weather = current['weather'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(28, 120, 28, 50),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getWeatherGradient(),
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1E3A8A).withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 0,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Weather Icon
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getWeatherIcon(weather['main']),
              size: 56,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 20),

          // Temperature
          Text(
            '${current['temp'].round()}°',
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w100,
              color: Colors.white,
              height: 0.9,
            ),
          ),

          SizedBox(height: 8),

          // Description
          Text(
            _capitalize(weather['description']),
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 0.5,
              fontWeight: FontWeight.w400,
            ),
          ),

          SizedBox(height: 28),

          // Quick Stats
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickStat(
                  'Feels like',
                  '${current['feels_like'].round()}°',
                  Icons.thermostat_outlined,
                ),
                _buildVerticalDivider(),
                _buildQuickStat(
                  'Humidity',
                  '${current['humidity']}%',
                  Icons.water_drop_outlined,
                ),
                _buildVerticalDivider(),
                _buildQuickStat(
                  'Wind',
                  '${current['wind_speed'].round()} m/s',
                  Icons.air,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 18),
        SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildHourlyForecast() {
    final hourlyData = weatherData!['hourly'] as List<dynamic>;

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourlyData.length,
        itemBuilder: (context, index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOutBack,
            child: _buildHourlyForecastCard(hourlyData[index], index),
          );
        },
      ),
    );
  }

  Widget _buildHourlyForecastCard(dynamic hour, int index) {
    final time = DateTime.fromMillisecondsSinceEpoch(hour['dt'] * 1000);
    final timeString = index == 0
        ? 'Now'
        : '${time.hour.toString().padLeft(2, '0')}:00';

    return Container(
      width: 85,
      margin: EdgeInsets.only(right: 12),
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade900.withValues(alpha: 0.6),
            Colors.grey.shade900.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            timeString,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          Icon(
            _getWeatherIcon(hour['weather']['main']),
            color: Colors.white,
            size: 32,
          ),
          Column(
            children: [
              Text(
                '${hour['temp'].round()}°',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (hour['pop'] > 0) ...[
                SizedBox(height: 2),
                Text(
                  '${hour['pop']}%',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade300),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailsGrid() {
    final current = weatherData!['current'];

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildDetailCard(
          'Pressure',
          '${current['pressure']}',
          'hPa',
          Icons.speed_rounded,
          Colors.orange.shade400,
        ),
        _buildSunsetSunriseCard(),
      ],
    );
  }

  Widget _buildDetailCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade900.withValues(alpha: 0.7),
            Colors.grey.shade900.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildSunsetSunriseCard() {
    final current = weatherData!['current'];
    final sunrise = DateTime.fromMillisecondsSinceEpoch(
      current['sunrise'] * 1000,
    );
    final sunset = DateTime.fromMillisecondsSinceEpoch(
      current['sunset'] * 1000,
    );

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade900.withValues(alpha: 0.7),
            Colors.grey.shade900.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wb_twilight_rounded,
                color: Colors.amber.shade400,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Sun Times',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Spacer(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sunrise',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                    Text(
                      '${sunrise.hour.toString().padLeft(2, '0')}:${sunrise.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sunset',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                    Text(
                      '${sunset.hour.toString().padLeft(2, '0')}:${sunset.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 16,
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
    );
  }

  Widget _buildDailyForecast() {
    final dailyData = weatherData!['daily'] as List<dynamic>;

    return Column(
      children: dailyData.map<Widget>((day) {
        final date = DateTime.fromMillisecondsSinceEpoch(day['dt'] * 1000);
        final dayName = _getDayName(date);

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.shade900.withValues(alpha: 0.6),
                Colors.grey.shade900.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Day name
              Expanded(
                flex: 2,
                child: Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),

              // Rain probability
              if (day['pop'] > 0) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade800.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${day['pop']}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 12),
              ],

              // Weather icon
              Icon(
                _getWeatherIcon(day['weather']['main']),
                color: Colors.white70,
                size: 28,
              ),

              SizedBox(width: 16),

              // Temperature range
              Text(
                '${day['temp']['max'].round()}° / ${day['temp']['min'].round()}°',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'clouds':
        return Icons.wb_cloudy_rounded;
      case 'rain':
        return Icons.umbrella_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'thunderstorm':
        return Icons.flash_on_rounded;
      case 'drizzle':
        return Icons.grain_rounded;
      case 'mist':
      case 'fog':
        return Icons.blur_on_rounded;
      default:
        return Icons.wb_sunny_rounded;
    }
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    final difference = targetDate.difference(today).inDays;

    switch (difference) {
      case 0:
        return 'Today';
      case 1:
        return 'Tomorrow';
      default:
        final weekdays = [
          'Sunday',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
        ];
        return weekdays[date.weekday % 7];
    }
  }

  String _getForecastTitle() {
    final hourlyData = weatherData!['hourly'] as List<dynamic>;
    if (hourlyData.isNotEmpty) {
      final isThreeHour = hourlyData[0]['isThreeHourInterval'] ?? true;
      return isThreeHour ? 'Forecast (3-hour intervals)' : 'Hourly Forecast';
    }
    return 'Forecast';
  }
}
