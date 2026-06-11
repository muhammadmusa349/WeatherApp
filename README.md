
# 🌤️ Weather App

A beautifully designed Flutter weather app with a deep purple dark theme, real-time weather data, and a smooth draggable detail sheet — built with clean MVC architecture.

<br/>


## 📱 Screenshots

<img width="702" height="1600" alt="WhatsApp Image 2026-06-11 at 2 27 37 PM" src="https://github.com/user-attachments/assets/ad8490f3-a1c7-411c-b50e-8d345158a48c" />
<img width="702" height="1600" alt="WhatsApp Image 2026-06-11 at 2 31 54 PM" src="https://github.com/user-attachments/assets/3a047b4e-e9b4-4656-b432-7bfcc92059ae" />

<br/>

## ✨ Features

- 🔍 **City Search** — Look up current weather for any city worldwide
- 🌡️ **Real-time Weather** — Temperature, feels like, high/low, and conditions
- 🕐 **Hourly Forecast** — 3-hour interval forecast with precipitation probability
- 💨 **Detailed Stats** — Air quality index, UV index, wind compass, sunrise/sunset arc, and rainfall
- 🎨 **Pixel-perfect UI** — Glassmorphism cards, starry gradient background, and animated draggable sheet
- 🏙️ **Default City** — Opens with Islamabad on first launch

<br/>

## 🏗️ Architecture

```
lib/
├── Model/
│   └── weather_model.dart       # Data models (WeatherModel, Main, Wind, Sys…)
├── Controller/
│   └── weather_controller.dart  # API calls, state management (ChangeNotifier)
└── View/
    └── home_screen.dart         # Full UI with persistent DraggableScrollableSheet
```

The app follows **MVC** with `provider` for state management — the controller fetches from three OpenWeatherMap endpoints (current weather, 5-day forecast, air pollution) and notifies the view.

<br/>

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- An [OpenWeatherMap](https://openweathermap.org/api) free API key

### Installation

```bash
git clone https://github.com/your-username/weather-app.git
cd weather-app
flutter pub get
```

Add your API key in `weather_controller.dart`:
```dart
final String _apiKey = 'YOUR_API_KEY_HERE';
```

Add your house asset in `pubspec.yaml`:
```yaml
assets:
  - assets/images/house.png
```

Then run:
```bash
flutter run
```

<br/>

## 📦 Dependencies

| Package | Purpose |
|--------|---------|
| `provider` | State management |
| `http` | REST API calls |

<br/>

## 🌐 APIs Used

- `GET /data/2.5/weather` — Current weather
- `GET /data/2.5/forecast` — 5-day / 3-hour forecast
- `GET /data/2.5/air_pollution` — Air quality index

All from [OpenWeatherMap](https://openweathermap.org/api).

<br/>

## 📄 License

This project is licensed under the [MIT License](LICENSE).
