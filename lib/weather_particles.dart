import 'package:flutter/material.dart';
import 'dart:math';

class WeatherParticles extends StatefulWidget {
  final String weatherCondition;
  final Widget child;

  const WeatherParticles({
    super.key,
    required this.weatherCondition,
    required this.child,
  });

  @override
  State<WeatherParticles> createState() => _WeatherParticlesState();
}

class _WeatherParticlesState extends State<WeatherParticles>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _initializeParticles();
  }

  void _initializeParticles() {
    particles.clear();
    final random = Random();

    if (_shouldShowParticles()) {
      for (int i = 0; i < _getParticleCount(); i++) {
        particles.add(
          Particle(
            x: random.nextDouble(),
            y: random.nextDouble(),
            speed: 0.02 + random.nextDouble() * 0.03,
            size: _getParticleSize(random),
            color: _getParticleColor(),
          ),
        );
      }
    }
  }

  bool _shouldShowParticles() {
    switch (widget.weatherCondition.toLowerCase()) {
      case 'rain':
      case 'drizzle':
      case 'snow':
      case 'mist':
      case 'fog':
        return true;
      default:
        return false;
    }
  }

  int _getParticleCount() {
    switch (widget.weatherCondition.toLowerCase()) {
      case 'rain':
        return 50;
      case 'drizzle':
        return 30;
      case 'snow':
        return 25;
      case 'mist':
      case 'fog':
        return 40;
      default:
        return 0;
    }
  }

  double _getParticleSize(Random random) {
    switch (widget.weatherCondition.toLowerCase()) {
      case 'rain':
      case 'drizzle':
        return 1.0 + random.nextDouble() * 2.0;
      case 'snow':
        return 2.0 + random.nextDouble() * 4.0;
      case 'mist':
      case 'fog':
        return 3.0 + random.nextDouble() * 6.0;
      default:
        return 2.0;
    }
  }

  Color _getParticleColor() {
    switch (widget.weatherCondition.toLowerCase()) {
      case 'rain':
      case 'drizzle':
        return Colors.lightBlue.withValues(alpha: 0.6);
      case 'snow':
        return Colors.white.withValues(alpha: 0.8);
      case 'mist':
      case 'fog':
        return Colors.grey.shade300.withValues(alpha: 0.4);
      default:
        return Colors.white.withValues(alpha: 0.5);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_shouldShowParticles())
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(
                    particles: particles,
                    animation: _controller.value,
                    weatherCondition: widget.weatherCondition,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class Particle {
  double x;
  double y;
  final double speed;
  final double size;
  final Color color;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animation;
  final String weatherCondition;

  ParticlePainter({
    required this.particles,
    required this.animation,
    required this.weatherCondition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var particle in particles) {
      // Update particle position
      particle.y += particle.speed;
      if (particle.y > 1.0) {
        particle.y = -0.1;
        particle.x = Random().nextDouble();
      }

      paint.color = particle.color;
      
      final x = particle.x * size.width;
      final y = particle.y * size.height;

      switch (weatherCondition.toLowerCase()) {
        case 'rain':
        case 'drizzle':
          // Draw rain drops as small lines
          canvas.drawLine(
            Offset(x, y),
            Offset(x - 2, y + particle.size * 8),
            paint..strokeWidth = particle.size,
          );
          break;
        case 'snow':
          // Draw snowflakes as circles
          canvas.drawCircle(
            Offset(x, y),
            particle.size,
            paint,
          );
          break;
        case 'mist':
        case 'fog':
          // Draw fog as soft circles
          final gradient = RadialGradient(
            colors: [
              particle.color,
              particle.color.withValues(alpha: 0.0),
            ],
          );
          paint.shader = gradient.createShader(
            Rect.fromCircle(center: Offset(x, y), radius: particle.size * 2),
          );
          canvas.drawCircle(
            Offset(x, y),
            particle.size * 2,
            paint,
          );
          paint.shader = null;
          break;
        default:
          canvas.drawCircle(
            Offset(x, y),
            particle.size,
            paint,
          );
          break;
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return true;
  }
}