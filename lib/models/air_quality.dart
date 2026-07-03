import 'package:flutter/material.dart';

class AirQuality {
  final int aqi;
  final String cityName;
  final DateTime timestamp;
  final List<Attribution> attributions;
  
  // Detailed Pollutants
  final String? pm25;
  final String? pm10;
  final String? o3;
  final String? no2;
  final String? so2;
  final String? co;

  // Weather Data
  final String? temperature;
  final String? wind;
  final String? humidity;
  final String? pressure;

  AirQuality({
    required this.aqi,
    required this.cityName,
    required this.timestamp,
    required this.attributions,
    this.pm25,
    this.pm10,
    this.o3,
    this.no2,
    this.so2,
    this.co,
    this.temperature,
    this.wind,
    this.humidity,
    this.pressure,
  });

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final iaqi = data['iaqi'] as Map<String, dynamic>? ?? {};

    return AirQuality(
      aqi: data['aqi'] as int,
      cityName: _cleanString(data['city']['name'] as String),
      timestamp: DateTime.parse(data['time']['s'] as String),
      attributions: (data['attributions'] as List?)
              ?.map((a) => Attribution.fromJson(a))
              .toList() ??
          [],
      // Parsing pollutants from iaqi
      pm25: iaqi['pm25']?['v']?.toString(),
      pm10: iaqi['pm10']?['v']?.toString(),
      o3: iaqi['o3']?['v']?.toString(),
      no2: iaqi['no2']?['v']?.toString(),
      so2: iaqi['so2']?['v']?.toString(),
      co: iaqi['co']?['v']?.toString(),
      // Parsing weather data
      temperature: iaqi['t']?['v']?.toString(),
      wind: iaqi['w']?['v']?.toString(),
      humidity: iaqi['h']?['v']?.toString(),
      pressure: iaqi['p']?['v']?.toString(),
    );
  }

  static String _cleanString(String text) {
    String cleaned = text.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[^\x00-\x7F]+'), '');
    return cleaned.trim();
  }

  String get status {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  /// Official WAQI Color Spectrum from demo
  Color get color {
    if (aqi <= 50) return const Color(0xFF009966);
    if (aqi <= 100) return const Color(0xFFFFDE33);
    if (aqi <= 150) return const Color(0xFFFF9933);
    if (aqi <= 200) return const Color(0xFFCC0033);
    if (aqi <= 300) return const Color(0xFF660099);
    return const Color(0xFF7E0023);
  }

  /// Text color for contrast based on official demo (Yellow has dark text)
  Color get textColor {
    if (aqi > 50 && aqi <= 150) return Colors.black; // Yellow and Orange use black text
    return Colors.white;
  }

  String get healthAdvice {
    if (aqi <= 50) return 'Safe for outdoor activities.';
    if (aqi <= 100) return 'Air quality is acceptable; however, for some pollutants there may be a moderate health concern.';
    if (aqi <= 150) return 'Members of sensitive groups may experience health effects.';
    if (aqi <= 200) return 'Everyone may begin to experience health effects.';
    if (aqi <= 300) return 'Health alert: everyone may experience more serious health effects.';
    return 'Health warnings of emergency conditions. The entire population is more likely to be affected.';
  }
}

class Attribution {
  final String name;
  final String url;

  Attribution({required this.name, required this.url});

  factory Attribution.fromJson(Map<String, dynamic> json) {
    return Attribution(
      name: _cleanString(json['name'] as String? ?? 'Unknown Source'),
      url: json['url'] as String? ?? '',
    );
  }

  static String _cleanString(String text) {
    String cleaned = text.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[^\x00-\x7F]+'), '');
    return cleaned.trim();
  }
}
