import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/Controller/weather_api_service.dart';
 
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
 
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
 
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
 
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
 
  double _sheetSize = _kInitialSize;
  bool _forecastTabHourly = true;
 
  static const double _kMinSize = 0.36;
  static const double _kInitialSize = 0.38;
  static const double _kMaxSize = 0.90;
  static const double _kExpandedThreshold = 0.52;
 
  bool get _isExpanded => _sheetSize >= _kExpandedThreshold;
 
  // ─── lifecycle ────────────────────────────────────────────────────────────
 
  @override
  void initState() {
    super.initState();
 
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
 
    _sheetController.addListener(() {
      if (mounted && _sheetController.isAttached) {
        final s = _sheetController.size;
        if ((s - _sheetSize).abs() > 0.005) {
          setState(() => _sheetSize = s);
        }
      }
    });
 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<WeatherController>()
          .fetchWeather('', city: 'Islamabad')
          .then((_) => _fadeController.forward());
    });
  }
 
  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
 
  // ─── build ────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherController>(
      builder: (context, controller, _) {
        return Scaffold(
          resizeToAvoidBottomInset: false, // prevents 140px keyboard overflow
          backgroundColor: const Color(0xFF0B0928),
          body: Stack(
            children: [
              const _StarryBackground(),
              _buildMainContent(controller),
              _buildPersistentSheet(controller),
            ],
          ),
        );
      },
    );
  }
 
  // ─── above-sheet content ──────────────────────────────────────────────────
 
  Widget _buildMainContent(WeatherController controller) {
    final size = MediaQuery.of(context).size;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final reservedForSheet = size.height * _kInitialSize - safeBottom;
 
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(controller),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: controller.isSearchFieldVisible
                ? _buildSearchField(controller)
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: controller.isLoading
                ? const _LoadingWidget()
                : controller.errorMessage.isNotEmpty
                    ? _ErrorWidget(message: controller.errorMessage)
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildCitySection(controller),
                      ),
          ),
          // Space so house doesn't hide behind the sheet
          SizedBox(height: reservedForSheet),
        ],
      ),
    );
  }
 
  Widget _buildTopBar(WeatherController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassBtn(icon: Icons.location_on_outlined, onTap: () {}),
          _GlassBtn(
            icon: controller.isSearchFieldVisible
                ? Icons.close_rounded
                : Icons.search_rounded,
            onTap: () {
              controller.toggleSearchField();
              if (!controller.isSearchFieldVisible) _searchController.clear();
            },
          ),
        ],
      ),
    );
  }
 
  Widget _buildSearchField(WeatherController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: const Color(0xFF9B6FFF),
              decoration: InputDecoration(
                hintText: 'Search city...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.white.withOpacity(0.4)),
              ),
              onSubmitted: (v) => _submitSearch(v, controller),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () =>
                _submitSearch(_searchController.text, controller),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B52F0), Color(0xFF5B2FD4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B52F0).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
 
  void _submitSearch(String city, WeatherController controller) {
    if (city.trim().isEmpty) return;
    _fadeController.reset();
    controller
        .fetchWeather('', city: city.trim())
        .then((_) => _fadeController.forward());
    _searchController.clear();
  }
 
  Widget _buildCitySection(WeatherController controller) {
    final w = controller.weatherData;
    if (w == null) return const SizedBox();
 
    final temp = w.main?.temp?.round() ?? 0;
    final tempMax = w.main?.tempMax?.round() ?? 0;
    final tempMin = w.main?.tempMin?.round() ?? 0;
    final desc = _cap(
        w.weather?.isNotEmpty == true
            ? (w.weather![0].description ?? '')
            : '');
    final city = w.name ?? '';
 
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 4),
        Text(city,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
        Text('$temp°',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 96,
                fontWeight: FontWeight.w200,
                height: 1.0,
                letterSpacing: -4)),
        Text(desc,
            style: TextStyle(
                color: Colors.white.withOpacity(0.65), fontSize: 18)),
        const SizedBox(height: 4),
        Text('H:$tempMax°   L:$tempMin°',
            style: TextStyle(
                color: Colors.white.withOpacity(0.65), fontSize: 16)),
        Expanded(child: _buildHouseImage()),
      ],
    );
  }
 
  Widget _buildHouseImage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFF5B2FD4).withOpacity(0.28),
              Colors.transparent,
            ]),
          ),
        ),
        ..._snowDots(),
        // Your house asset – swap 'assets/images/house.png' with your path
        Image.asset(
          'assets/images/house.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Text('🏠', style: TextStyle(fontSize: 120)),
        ),
      ],
    );
  }
 
  List<Widget> _snowDots() {
    final rng = math.Random(7);
    return List.generate(14, (i) {
      final x = (rng.nextDouble() - 0.5) * 200;
      final y = (rng.nextDouble() - 0.5) * 200;
      final s = rng.nextDouble() * 5 + 2;
      return Positioned(
        left: 120 + x,
        top: 120 + y,
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(rng.nextDouble() * 0.45 + 0.15),
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }
 
  // ─── persistent draggable sheet ───────────────────────────────────────────
 
  Widget _buildPersistentSheet(WeatherController controller) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: _kInitialSize,
      minChildSize: _kMinSize,
      maxChildSize: _kMaxSize,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A1C6E), Color(0xFF18114A)],
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
            border:
                Border.all(color: Colors.white.withOpacity(0.10), width: 1),
          ),
          child: CustomScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              // Drag handle
              SliverToBoxAdapter(child: _handle()),
 
              // City header — only when expanded
              SliverToBoxAdapter(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? _sheetCityHeader(controller)
                      : const SizedBox.shrink(),
                ),
              ),
 
              // Forecast tabs + hourly list — always visible
              SliverToBoxAdapter(
                  child: _forecastSection(controller)),
 
              // Bottom nav — only when collapsed
              SliverToBoxAdapter(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? const SizedBox.shrink()
                      : _bottomNav(),
                ),
              ),
 
              // Detail cards — only when expanded
              SliverToBoxAdapter(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? _detailCards(controller)
                      : const SizedBox.shrink(),
                ),
              ),
 
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
 
  Widget _handle() => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 6),
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
 
  Widget _sheetCityHeader(WeatherController controller) {
    final w = controller.weatherData;
    final temp = w?.main?.temp?.round() ?? 0;
    final city = w?.name ?? '';
    final desc = _cap(w?.weather?.isNotEmpty == true
        ? (w!.weather![0].description ?? '')
        : '');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Column(
        children: [
          Text(city,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('$temp° | $desc',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65), fontSize: 15)),
        ],
      ),
    );
  }
 
  Widget _forecastSection(WeatherController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                _ForecastTab(
                  label: 'Hourly Forecast',
                  isActive: _forecastTabHourly,
                  onTap: () =>
                      setState(() => _forecastTabHourly = true),
                ),
                const SizedBox(width: 28),
                _ForecastTab(
                  label: 'Weekly Forecast',
                  isActive: !_forecastTabHourly,
                  onTap: () =>
                      setState(() => _forecastTabHourly = false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 12),
          SizedBox(
            height: 126,
            child:
                _HourlyForecastList(forecasts: controller.hourlyForecast),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
 
  Widget _bottomNav() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        32,
        4,
        32,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.location_on_outlined,
              color: Colors.white.withOpacity(0.60), size: 26),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.22),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.add,
                color: Color(0xFF1E1458), size: 28),
          ),
          Icon(Icons.format_list_bulleted_rounded,
              color: Colors.white.withOpacity(0.60), size: 26),
        ],
      ),
    );
  }
 
  Widget _detailCards(WeatherController controller) {
    final w = controller.weatherData;
    final aqi =
        controller.airQualityData?['main']?['aqi'] as int?;
    final sunrise = w?.sys?.sunrise != null
        ? DateTime.fromMillisecondsSinceEpoch(w!.sys!.sunrise! * 1000)
        : null;
    final sunset = w?.sys?.sunset != null
        ? DateTime.fromMillisecondsSinceEpoch(w!.sys!.sunset! * 1000)
        : null;
    double rainfall = 0.0;
    if (controller.hourlyForecast.isNotEmpty) {
      final rain = controller.hourlyForecast[0]['rain'];
      if (rain != null) rainfall = (rain['3h'] as double?) ?? 0.0;
    }
 
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        children: [
          _AirQualityCard(aqi: aqi),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              children: [
                const Expanded(child: _UVIndexCard()),
                const SizedBox(width: 12),
                Expanded(
                    child: _SunriseCard(
                        sunrise: sunrise, sunset: sunset)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _WindCard(wind: w?.wind)),
                const SizedBox(width: 12),
                Expanded(child: _RainfallCard(rainfall: rainfall)),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  String _cap(String s) => s
      .split(' ')
      .map((w) =>
          w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
 
// =============================================================================
//  Hourly forecast list
// =============================================================================
 
class _HourlyForecastList extends StatelessWidget {
  final List<dynamic> forecasts;
  const _HourlyForecastList({required this.forecasts});
 
  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) {
      return Center(
        child: Text('No forecast data',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 13)),
      );
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: forecasts.length > 8 ? 8 : forecasts.length,
      itemBuilder: (_, i) {
        final item = forecasts[i];
        final dt = DateTime.fromMillisecondsSinceEpoch(
            (item['dt'] as int) * 1000);
        final temp = (item['main']['temp'] as num).toDouble().round();
        final pop = ((item['pop'] as num? ?? 0).toDouble() * 100).round();
        final icon = item['weather'][0]['icon'] as String;
        
        return _HourlyCard(
          time: i == 0 ? 'Now' : _fmt(dt),
          temp: '$temp°',
          icon: icon,
          precipitation: pop > 0 ? '$pop%' : null,
          isNow: i == 0,
        );
      },
    );
  }
 
  static String _fmt(DateTime dt) {
    final h = dt.hour;
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }
}
 
class _HourlyCard extends StatelessWidget {
  final String time, temp, icon;
  final String? precipitation;
  final bool isNow;
  const _HourlyCard({
    required this.time,
    required this.temp,
    required this.icon,
    this.precipitation,
    this.isNow = false,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: isNow
            ? const LinearGradient(
                colors: [Color(0xFF7B52F0), Color(0xFF5232C8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isNow ? null : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNow
              ? const Color(0xFF9B6FFF).withOpacity(0.6)
              : Colors.white.withOpacity(0.10),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          Image.network(
            'https://openweathermap.org/img/wn/$icon@2x.png',
            width: 38,
            height: 38,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.cloud, color: Colors.white, size: 28),
          ),
          SizedBox(
            height: 17,
            child: precipitation != null
                ? Text(precipitation!,
                    style: const TextStyle(
                        color: Color(0xFF5CD8FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w500))
                : null,
          ),
          Text(temp,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
 
// =============================================================================
//  Detail card widgets
// =============================================================================
 
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(22),
          border:
              Border.all(color: Colors.white.withOpacity(0.11), width: 1),
        ),
        child: child,
      );
}
 
class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CardHeader({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.5), size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1)),
        ],
      );
}
 
/// Gradient progress bar — uses Align instead of LayoutBuilder to avoid
/// IntrinsicHeight conflicts.
class _GradientBar extends StatelessWidget {
  final double progress;
  final List<Color> colors;
  const _GradientBar({required this.progress, required this.colors});
 
  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 5,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Positioned.fill(
          top: -4,
          bottom: -4,
          child: Align(
            alignment: Alignment(p * 2 - 1, 0),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border:
                    Border.all(color: const Color(0xFF7B52F0), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B52F0).withOpacity(0.55),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
 
class _AirQualityCard extends StatelessWidget {
  final int? aqi;
  const _AirQualityCard({this.aqi});
 
  static String _lbl(int? v) => const {
        1: 'Good',
        2: 'Fair',
        3: 'Low Health Risk',
        4: 'Poor',
        5: 'Very Poor'
      }[v] ??
      'Unknown';
 
  @override
  Widget build(BuildContext context) {
    final p = aqi != null ? ((aqi! - 1) / 4.0) : 0.2;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(icon: Icons.air_rounded, label: 'AIR QUALITY'),
          const SizedBox(height: 8),
          Text('${aqi ?? '--'} - ${_lbl(aqi)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _GradientBar(
            progress: p,
            colors: const [
              Color(0xFF4DC6FF),
              Color(0xFF9B6FFF),
              Color(0xFFFF6BAE)
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('See more',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.45), size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
 
class _UVIndexCard extends StatelessWidget {
  const _UVIndexCard();
  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
              icon: Icons.wb_sunny_outlined, label: 'UV INDEX'),
          const SizedBox(height: 10),
          const Text('4',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  height: 1)),
          const SizedBox(height: 2),
          Text('Moderate',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75), fontSize: 14)),
          const SizedBox(height: 14),
          const _GradientBar(
            progress: 4 / 11,
            colors: [
              Color(0xFF4DC6FF),
              Color(0xFFFFD66B),
              Color(0xFFFF6BAE)
            ],
          ),
        ],
      ),
    );
  }
}
 
class _SunriseCard extends StatelessWidget {
  final DateTime? sunrise;
  final DateTime? sunset;
  const _SunriseCard({this.sunrise, this.sunset});
 
  static String _fmt(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = h < 12 ? 'AM' : 'PM';
    final d = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$d:$m $p';
  }
 
  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
              icon: Icons.wb_twilight_rounded, label: 'SUNRISE'),
          const SizedBox(height: 10),
          Text(sunrise != null ? _fmt(sunrise!) : '--:-- AM',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: CustomPaint(
              painter:
                  _SunArcPainter(sunrise: sunrise, sunset: sunset),
            ),
          ),
          const SizedBox(height: 8),
          Text(
              sunset != null ? 'Sunset: ${_fmt(sunset!)}' : 'Sunset: --',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ],
      ),
    );
  }
}
 
class _WindCard extends StatelessWidget {
  final dynamic wind;
  const _WindCard({this.wind});
  @override
  Widget build(BuildContext context) {
    final speed = (wind?.speed ?? 0.0) as double;
    final deg = (wind?.deg ?? 0) as int;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(icon: Icons.air_rounded, label: 'WIND'),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              width: 88,
              height: 88,
              child: CustomPaint(
                  painter:
                      _CompassPainter(degrees: deg.toDouble())),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text('${(speed * 3.6).toStringAsFixed(1)} km/h',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
 
class _RainfallCard extends StatelessWidget {
  final double rainfall;
  const _RainfallCard({required this.rainfall});
  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
              icon: Icons.water_drop_outlined, label: 'RAINFALL'),
          const SizedBox(height: 10),
          Text('${rainfall.toStringAsFixed(1)} mm',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('in last hour',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65), fontSize: 14)),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.water_drop,
                  color: Color(0xFF5CD8FF), size: 13),
              const SizedBox(width: 5),
              Text(
                  rainfall > 0
                      ? 'Active rainfall'
                      : 'No rain expected',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
 
// =============================================================================
//  Small shared widgets
// =============================================================================
 
class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}
 
class _ForecastTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _ForecastTab(
      {required this.label, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.45),
                    fontSize: 14,
                    fontWeight: isActive
                        ? FontWeight.w600
                        : FontWeight.w400)),
            if (isActive) ...[
              const SizedBox(height: 4),
              Container(
                height: 2.5,
                width: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF9B6FFF), Color(0xFF5CD8FF)]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      );
}
 
// =============================================================================
//  Custom painters
// =============================================================================
 
class _SunArcPainter extends CustomPainter {
  final DateTime? sunrise;
  final DateTime? sunset;
  _SunArcPainter({this.sunrise, this.sunset});
 
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
 
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..quadraticBezierTo(
            size.width / 2, 0, size.width, size.height),
      paint,
    );
 
    double t = 0.5;
    if (sunrise != null && sunset != null) {
      final now = DateTime.now();
      final total =
          sunset!.difference(sunrise!).inSeconds.toDouble();
      final elapsed =
          now.difference(sunrise!).inSeconds.toDouble();
      t = (elapsed / total).clamp(0.0, 1.0);
    }
 
    final cx = t * size.width;
    final cy = math.pow(1 - t, 2) * size.height +
        math.pow(t, 2) * size.height;
 
    canvas.drawCircle(Offset(cx, cy.toDouble()), 6,
        Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(cx, cy.toDouble()),
      6,
      Paint()
        ..color = const Color(0xFF9B6FFF).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
 
  @override
  bool shouldRepaint(_) => false;
}
 
class _CompassPainter extends CustomPainter {
  final double degrees;
  _CompassPainter({required this.degrees});
 
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
 
    canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = Colors.white.withOpacity(0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
 
    for (int i = 0; i < 12; i++) {
      final a = i * math.pi * 2 / 12;
      canvas.drawLine(
        Offset(center.dx + (r - 7) * math.cos(a),
            center.dy + (r - 7) * math.sin(a)),
        Offset(center.dx + (r - 2) * math.cos(a),
            center.dy + (r - 2) * math.sin(a)),
        Paint()
          ..color = Colors.white.withOpacity(0.20)
          ..strokeWidth = 1,
      );
    }
 
    _lbl(canvas, center, r, 'N', -math.pi / 2);
    _lbl(canvas, center, r, 'E', 0);
    _lbl(canvas, center, r, 'W', math.pi);
 
    final rad = (degrees - 90) * math.pi / 180;
    final tip = Offset(center.dx + (r - 12) * math.cos(rad),
        center.dy + (r - 12) * math.sin(rad));
    final tail = Offset(center.dx - 14 * math.cos(rad),
        center.dy - 14 * math.sin(rad));
 
    canvas.drawLine(
        center,
        tip,
        Paint()
          ..color = const Color(0xFF9B6FFF).withOpacity(0.28)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(
        tail,
        tip,
        Paint()
          ..color = const Color(0xFF9B6FFF)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round);
 
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);
    canvas.drawCircle(
        center,
        4,
        Paint()
          ..color = const Color(0xFF7B52F0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }
 
  void _lbl(Canvas c, Offset center, double r, String t, double a) {
    final pos = Offset(center.dx + (r - 17) * math.cos(a),
        center.dy + (r - 17) * math.sin(a));
    final tp = TextPainter(
      text: TextSpan(
          text: t,
          style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, pos - Offset(tp.width / 2, tp.height / 2));
  }
 
  @override
  bool shouldRepaint(_CompassPainter old) => old.degrees != degrees;
}
 
// =============================================================================
//  Background + state widgets
// =============================================================================
 
class _StarryBackground extends StatelessWidget {
  const _StarryBackground();
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0928),
              Color(0xFF1A1150),
              Color(0xFF261870)
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _StarsPainter(),
          child: const SizedBox.expand(),
        ),
      );
}
 
class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    for (int i = 0; i < 120; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.65;
      final r = rng.nextDouble() * 1.4 + 0.3;
      final op = rng.nextDouble() * 0.65 + 0.15;
      canvas.drawCircle(Offset(x, y), r,
          Paint()..color = Colors.white.withOpacity(op));
    }
  }
 
  @override
  bool shouldRepaint(_) => false;
}
 
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(
            color: Color(0xFF9B6FFF), strokeWidth: 2.5),
      );
}
 
class _ErrorWidget extends StatelessWidget {
  final String message;
  const _ErrorWidget({required this.message});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                color: Colors.white.withOpacity(0.35), size: 64),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                message,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 16,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
}