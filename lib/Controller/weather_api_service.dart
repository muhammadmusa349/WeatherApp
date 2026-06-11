import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/Model/weather_model.dart';

class WeatherController extends ChangeNotifier {
  WeatherModel? weatherData;
  
  // New variables to hold data for the Figma UI elements
  List<dynamic> hourlyForecast = [];
  Map<String, dynamic>? airQualityData;

  bool isLoading = false;
  bool isSearchFieldVisible = false; // Tracks the visibility of the search input field
  String errorMessage = '';

  // API key loaded from .env file — never hardcode secrets in source code
  final String _apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';

  /// Fetches weather data, forecast, and air quality for a specific city. Defaults to Islamabad.
  Future<void> fetchWeather(String s, {String city = "Islamabad"}) async {
    if (city.trim().isEmpty) return;

    isLoading = true;
    errorMessage = '';
    // Hides search field once data is submitted
    isSearchFieldVisible = false;
    notifyListeners();

    try {
      // 1. Fetch Current Weather
      final weatherUrl = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=${city.trim()}&appid=$_apiKey&units=metric');
      
      final weatherResponse = await http.get(weatherUrl);

      if (weatherResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(weatherResponse.body);
        weatherData = WeatherModel.fromJson(data);

        // Extract coordinates needed for the Air Quality API
        final lat = data['coord']['lat'];
        final lon = data['coord']['lon'];

        // 2. Fetch 5-Day / 3-Hour Forecast (For the Hourly UI tab)
        final forecastUrl = Uri.parse(
            'https://api.openweathermap.org/data/2.5/forecast?q=${city.trim()}&appid=$_apiKey&units=metric');
        final forecastResponse = await http.get(forecastUrl);
        
        if (forecastResponse.statusCode == 200) {
          final Map<String, dynamic> forecastJson = json.decode(forecastResponse.body);
          hourlyForecast = forecastJson['list'] ?? [];
        }

        // 3. Fetch Air Pollution Data (For the Air Quality Card)
        final aqiUrl = Uri.parse(
            'https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$_apiKey');
        final aqiResponse = await http.get(aqiUrl);

        if (aqiResponse.statusCode == 200) {
          final Map<String, dynamic> aqiJson = json.decode(aqiResponse.body);
          // Grab the main pollution data point
          airQualityData = aqiJson['list'] != null && aqiJson['list'].isNotEmpty 
              ? aqiJson['list'][0] 
              : null;
        }

      } else if (weatherResponse.statusCode == 404) {
        errorMessage = 'City not found. Please try again.';
        weatherData = null;
        hourlyForecast = [];
        airQualityData = null;
      } else {
        errorMessage = 'Failed to fetch weather data. Please try again later.';
        weatherData = null;
      }
    } catch (e) {
      errorMessage = 'A network error occurred. Please check your connection.';
      weatherData = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles the visibility of the interactive search input field.
  void toggleSearchField() {
    isSearchFieldVisible = !isSearchFieldVisible;
    if (isSearchFieldVisible) {
      errorMessage = ''; // Clear error when searching again
    }
    notifyListeners();
  }
}