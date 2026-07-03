import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/air_quality.dart';

class AqiDashboardBox extends StatelessWidget {
  final AirQuality? airQuality;

  const AqiDashboardBox({super.key, this.airQuality});

  @override
  Widget build(BuildContext context) {
    if (airQuality == null) {
      return _buildLoadingState();
    }

    final aq = airQuality!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
        ),
        child: Column(
          children: [
            _buildHeader(aq),
            const SizedBox(height: 24),
            _buildMainAqi(aq),
            const SizedBox(height: 24),
            _buildWeatherRow(aq),
            const Divider(height: 32, color: Colors.white10),
            _buildPollutantGrid(aq),
            const SizedBox(height: 16),
            _buildAttribution(aq),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AirQuality aq) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "AIR QUALITY",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              aq.cityName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.air_rounded, color: Colors.cyan, size: 20),
        ),
      ],
    );
  }

  Widget _buildMainAqi(AirQuality aq) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: aq.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: aq.color.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  aq.aqi.toString(),
                  style: TextStyle(
                    color: aq.textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  "AQI",
                  style: TextStyle(
                    color: aq.textColor.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          aq.status.toUpperCase(),
          style: TextStyle(
            color: aq.color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            aq.healthAdvice,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherRow(AirQuality aq) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (aq.temperature != null) _buildIndicator(Icons.thermostat_rounded, '${aq.temperature}°C', 'Temp'),
        if (aq.humidity != null) _buildIndicator(Icons.water_drop_rounded, '${aq.humidity}%', 'Hum'),
        if (aq.wind != null) _buildIndicator(Icons.air_rounded, '${aq.wind}m/s', 'Wind'),
      ],
    );
  }

  Widget _buildPollutantGrid(AirQuality aq) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        if (aq.pm25 != null) _buildPollutantTag('PM2.5', aq.pm25!),
        if (aq.pm10 != null) _buildPollutantTag('PM10', aq.pm10!),
        if (aq.no2 != null) _buildPollutantTag('NO₂', aq.no2!),
        if (aq.o3 != null) _buildPollutantTag('O₃', aq.o3!),
        if (aq.so2 != null) _buildPollutantTag('SO₂', aq.so2!),
        if (aq.co != null) _buildPollutantTag('CO', aq.co!),
      ],
    );
  }

  Widget _buildIndicator(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPollutantTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttribution(AirQuality aq) {
    final name = aq.attributions.isNotEmpty ? aq.attributions.first.name : "WAQI Data Platform";
    return Text(
      "Source: $name",
      style: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.5),
        fontSize: 9,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                "Fetching Real-time Air Quality...",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
