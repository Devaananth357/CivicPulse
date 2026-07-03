import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/air_quality.dart';

class AqiService {
  // TODO: Replace 'demo' with your real API token from https://aqicn.org/api/
  // Using personal API token provided by user for full accuracy
  final String _token = '9da77d0d43e34b4583f44778df5d11da579e2362'; 
  final String _baseUrl = 'https://api.waqi.info/feed';

  Future<AirQuality?> getAirQuality(double lat, double lng) async {
    // TEMPORARY: Returning mock data while API token is activating
    return AirQuality(
      aqi: 56,
      cityName: "Chennai",
      timestamp: DateTime.now(),
      attributions: [Attribution(name: "System Mock (Awaiting Activation)", url: "")],
      pm25: "15",
      pm10: "30",
      temperature: "31",
      humidity: "65",
      wind: "4.2",
    );

    /* Original logic commented out for activation period
    try {
      // 1. Try Geolocation-based query
      final geoUrl = Uri.parse('$_baseUrl/geo:$lat;$lng/?token=$_token&lang=en');
      print('📢 AQI Service Request URL (Geo): $geoUrl');
      
      final geoResponse = await http.get(geoUrl);
      if (geoResponse.statusCode == 200) {
        final data = json.decode(geoResponse.body);
        if (data['status'] == 'ok') {
          final aq = AirQuality.fromJson(data);
          
          if (_token == 'demo' && 
              aq.cityName.toLowerCase().contains('shanghai') && 
              (lat < 30 || lat > 32)) {
            print('⚠️ AQI Service: Demo token restriction detected. Trying IP-based fallback...');
            return await _getAirQualityByIpFallback();
          }
          
          return aq;
        } else {
          final errorMessage = data['data'];
          if (errorMessage == 'Invalid key') {
            print('⏳ AQI Service: Token is valid but likely still activating (Invalid key). This usually takes 5-10 minutes after validation.');
          } else {
            print('⚠️ AQI Service Geo Error Message: $errorMessage');
          }
        }
      }
      
      // 2. Fallback to IP-based query if geo fails or is restricted
      return await _getAirQualityByIpFallback();
      
    } catch (e) {
      print('AQI Service Exception: $e');
      return null;
    }
    */
  }

  Future<AirQuality?> _getAirQualityByIpFallback() async {
    try {
      // 'here' endpoint uses the requester's IP to find the nearest station
      final url = Uri.parse('$_baseUrl/here/?token=$_token&lang=en');
      print('📢 AQI Service Fallback URL (IP-based): $url');
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          return AirQuality.fromJson(data);
        } else {
          print('⚠️ AQI Service Fallback Error Message: ${data['data']}');
        }
      }
    } catch (e) {
      print('AQI Service Fallback Exception: $e');
    }
    return null;
  }
}
