import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warmapp/constants.dart';
import 'package:warmapp/models/Sensordata.dart';
import 'package:warmapp/models/Timeserie.dart';
import 'package:warmapp/models/metric.dart';
import 'package:warmapp/services/sensor_service.dart';
import 'package:warmapp/widgets/zoomable_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  SensorService _sensorService = SensorService();
  final List<Color> _gradientColors = [
    const Color(0xFF6FFF7C),
    const Color(0xFF0087FF),
    const Color(0xFF5620FF),
  ];
  List<FlSpot> _values = const [];
  MapEntry<String, String>? _selectedValue;
  List<MapEntry<String, String>> _devices = [];

  List<String> modes = ["Day", "Week", "Month"];
  String _currentMode = "Day";
  Metric _currentMetric = Metric.temperature;
  double _minY = double.infinity;
  double _maxY = double.negativeInfinity;
  double _minX = double.infinity;
  double _maxX = double.negativeInfinity;
  double _defaultMinX = double.infinity;
  double _defaultMaxX = double.negativeInfinity;
  double lastMinXValue = 0;
  double lastMaxXValue = 0;

  Future<List<SensorData>> getSensorData(String? deviceId) async {
    if (deviceId == null) {
      return [];
    }
    List<TimeSerie> data = await _sensorService.getSensorData(deviceId);
    List<SensorData> result = [];
    for (TimeSerie t in data) {
      double temperature = double.parse(t.context.temperature.toString());
      double humidity = double.parse(t.context.humidity.toString());
      double battery = double.parse(t.context.battery.toString());
      DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(
          int.parse(t.context.timeOfSample));
      result.add(SensorData(
          timestamp: timestamp,
          temperature: temperature,
          humidity: humidity,
          battery: battery));
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
  }

  void _getDevices() async {
    Map<String, String> devices = await _sensorService.getDevices();
    var devicesList = devices.entries.toList();
    devicesList.sort((a, b) => a.value.compareTo(b.value));
    devices = Map.fromEntries(devicesList);
    debugPrint(devices.toString());
    setState(() {
      _devices = devices.entries.toList();
    });
  }

  void _prepareSensorData(MapEntry<String, String>? device) async {
    List<SensorData> data = await getSensorData(device?.key);
    _minX = double.infinity;
    _maxX = double.negativeInfinity;
    _minY = double.infinity;
    _maxY = double.negativeInfinity;

    _values = data.map((d) {
      var currentMetric = switch (_currentMetric) {
        Metric.temperature => d.temperature,
        Metric.humidity => d.humidity,
        _ => d.battery
      };
      if (currentMetric < _minY) {
        _minY = currentMetric;
      }
      if (d.timestamp.millisecondsSinceEpoch.toDouble() < _minX) {
        _minX = d.timestamp.millisecondsSinceEpoch.toDouble();
      }
      if (currentMetric > _maxY) {
        _maxY = currentMetric;
      }
      if (d.timestamp.millisecondsSinceEpoch.toDouble() > _maxX) {
        _maxX = d.timestamp.millisecondsSinceEpoch.toDouble();
      }
      return FlSpot(
        d.timestamp.millisecondsSinceEpoch.toDouble(),
        currentMetric,
      );
    }).toList();
    _minX = truncateTime(_minX.toInt(), _currentMode).toDouble();
    _maxX = roundToLastTime(_minX.toInt(), _currentMode).toDouble();
    _defaultMinX = _minX;
    _defaultMaxX = _maxX;

    setState(() {});
  }

  LineChartData _mainData() {
    return LineChartData(
      lineTouchData: LineTouchData(
          enabled: false,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots
                  .map((e) => LineTooltipItem(
                      "${e.y}${_currentMetric.metric}\n${DateFormat("dd.MM HH:mm").format(DateTime.fromMillisecondsSinceEpoch(e.x.toInt()))}",
                      TextStyle(fontSize: 10)))
                  .toList();
            },
          )),
      gridData: _gridData(),
      titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: _bottomTitles(),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: _topTitles()),
          leftTitles: AxisTitles(
            sideTitles: _leftTitles(),
          )),
      borderData: FlBorderData(
        show: !true,
        border: Border.all(color: Colors.white12, width: 1),
      ),
      minX: _minX,
      maxX: _maxX,
      minY: _minY,
      maxY: _maxY,
      lineBarsData: [_lineBarData()],
    );
  }

  LineChartBarData _lineBarData() {
    return LineChartBarData(
      spots: _values,
      gradient: LinearGradient(colors: _gradientColors),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
            colors: _gradientColors
                .map((color) => color.withOpacity(0.3))
                .toList()),
      ),
    );
  }

  SideTitles _topTitles() {
    return SideTitles(
      showTitles: false,
      getTitlesWidget: (value, meta) {
        return Text("");
      },
    );
  }

  SideTitles _leftTitles() {
    return SideTitles(
      showTitles: true,
      getTitlesWidget: (value, meta) {
        if (value == meta.max || value == meta.min) {
          return SideTitleWidget(
              axisSide: AxisSide.left,
              child: Text("$value${_currentMetric.metric}",
                  style: TextStyle(fontSize: 10)));
        } else {
          return Container();
        }
      },
      reservedSize: 50,
      //interval: ((_maxY - _minY) / 3.0).ceilToDouble()
    );
  }

  String getDateFormat(DateTime date) {
    switch (_currentMode) {
      case "Day":
        return DateFormat("dd.MMM").format(date);
      case "Week":
        return DateFormat("dd.MMM").format(date);
      case "Month":
        return DateFormat("dd.MMM").format(date);
      default:
        throw ArgumentError(
            "Invalid mode. Supported modes are: 'Day', 'Week', 'Month'");
    }
  }

  SideTitles _bottomTitles() {
    return SideTitles(
      showTitles: true,
      //reservedSize: 100,
      getTitlesWidget: (value, meta) {
        if (value == meta.max || value == meta.min) {
          final DateTime date =
              DateTime.fromMillisecondsSinceEpoch(value.toInt());
          return SideTitleWidget(
            axisSide: AxisSide.bottom,
            child: Text(getDateFormat(date), style: TextStyle(fontSize: 10)),
          );
        } else {
          return Container();
        }
      },
      //interval: (_maxX - _minX) / 1.0,
    );
  }

  FlGridData _gridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (value) {
        return const FlLine(
          color: Colors.white12,
          strokeWidth: 0.5,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("Warmapp")),
      floatingActionButton: FloatingActionButton(
        child: Text("Devices"),
        onPressed: () => _getDevices(),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<MapEntry<String, String>>(
                  value: _selectedValue,
                  items: _devices
                      .map((e) => DropdownMenuItem<MapEntry<String, String>>(
                          value: e, child: Text(e.value)))
                      .toList(),
                  onChanged: (MapEntry<String, String>? newValue) {
                    setState(() {
                      _selectedValue = newValue!;
                      _prepareSensorData(newValue);
                    });
                  }),
              SizedBox(
                width: 10,
              ),
              DropdownButton<String>(
                  value: _currentMode,
                  items: modes
                      .map((e) =>
                          DropdownMenuItem<String>(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _currentMode = newValue!;
                      _prepareSensorData(_selectedValue);
                    });
                  }),
              SizedBox(
                width: 10,
              ),
              DropdownButton<Metric>(
                  value: _currentMetric,
                  items: Metric.values
                      .map((e) => DropdownMenuItem<Metric>(
                          value: e, child: Text(e.name)))
                      .toList(),
                  onChanged: (Metric? newValue) {
                    setState(() {
                      _currentMetric = newValue!;
                      _prepareSensorData(_selectedValue);
                    });
                  })
            ],
          ),
          AspectRatio(
              aspectRatio: 16 / 9,
              child: _values.isEmpty
                  ? Placeholder()
                  : GestureDetector(
                      onDoubleTap: () {
                        setState(() {
                          _minX = _defaultMinX;
                          _maxX = _defaultMaxX;
                        });
                      },
                      onHorizontalDragStart: (details) {
                        lastMinXValue = _minX;
                        lastMaxXValue = _maxX;
                      },
                      onHorizontalDragUpdate: (details) {
                        var horizontalDistance = details.primaryDelta ?? 0;
                        if (horizontalDistance == 0) return;
                        debugPrint("Horizontal distance: $horizontalDistance");
                        var lastMinMaxDistance =
                            max(lastMaxXValue - lastMinXValue, 0.0);

                        setState(() {
                          _minX -=
                              lastMinMaxDistance * 0.005 * horizontalDistance;
                          _maxX -=
                              lastMinMaxDistance * 0.005 * horizontalDistance;
                        });
                      },
                      onScaleStart: (details) {
                        lastMinXValue = _minX;
                        lastMaxXValue = _maxX;
                      },
                      onScaleUpdate: (details) {
                        var horizontalScale = details.horizontalScale;
                        if (horizontalScale == 0) return;
                        debugPrint("Horizontal scale: $horizontalScale");
                        var lastMinMaxDistance =
                            max(lastMaxXValue - lastMinXValue, 0);
                        var newMinMaxDistance =
                            max(lastMinMaxDistance / horizontalScale, 10);
                        var distanceDifference =
                            newMinMaxDistance - lastMinMaxDistance;
                        setState(() {
                          final newMinX = max(
                            lastMinXValue - distanceDifference,
                            0.0,
                          );
                          final newMaxX = min(
                            lastMaxXValue + distanceDifference,
                            _defaultMaxX,
                          );

                          if (newMaxX - newMinX > 2) {
                            _minX = newMinX;
                            _maxX = newMaxX;
                          }
                        });
                      },
                      child: LineChart(_mainData()))),
        ],
      ),
    );
  }

  int truncateToDay(int currentTimeMillis) {
    final DateTime currentDate =
        DateTime.fromMillisecondsSinceEpoch(currentTimeMillis);
    return DateTime(currentDate.year, currentDate.month, currentDate.day)
        .millisecondsSinceEpoch;
  }

  int truncateToWeek(int currentTimeMillis) {
    final DateTime currentDate =
        DateTime.fromMillisecondsSinceEpoch(currentTimeMillis);
    final int daysToSubtract = currentDate.weekday - 1;
    final int truncatedMillis = truncateToDay(currentTimeMillis);
    return truncatedMillis - (daysToSubtract * 24 * 60 * 60 * 1000);
  }

  int truncateToMonth(int currentTimeMillis) {
    final DateTime currentDate =
        DateTime.fromMillisecondsSinceEpoch(currentTimeMillis);
    final int daysToSubtract = currentDate.day - 1;
    final int truncatedMillis = truncateToDay(currentTimeMillis);
    return truncatedMillis - (daysToSubtract * 24 * 60 * 60 * 1000);
  }

  int truncateTime(int currentTimeMillis, String mode) {
    switch (mode) {
      case "Day":
        return truncateToDay(currentTimeMillis);
      case "Week":
        return truncateToDay(currentTimeMillis);
      case "Month":
        return truncateToDay(currentTimeMillis);
      default:
        throw ArgumentError(
            "Invalid mode. Supported modes are: 'Day', 'Week', 'Month'");
    }
  }

  int roundToNextDay(int currentTimeMillis) {
    return truncateToDay(currentTimeMillis) + (24 * 60 * 60 * 1000);
  }

  int roundToNextWeek(int currentTimeMillis) {
    //final DateTime currentDate =
    //    DateTime.fromMillisecondsSinceEpoch(currentTimeMillis);
    final int daysToAdd = 7; //- currentDate.weekday;
    final int truncatedMillis = truncateToDay(currentTimeMillis);
    return truncatedMillis + (daysToAdd * 24 * 60 * 60 * 1000);
  }

  int roundToNextMonth(int currentTimeMillis) {
    final DateTime currentDate =
        DateTime.fromMillisecondsSinceEpoch(currentTimeMillis);
    final int daysToAdd =
        DateTime(currentDate.year, currentDate.month + 1, currentDate.day)
            .difference(currentDate)
            .inDays;
    final int truncatedMillis = truncateToDay(currentTimeMillis);
    return truncatedMillis + (daysToAdd * 24 * 60 * 60 * 1000);
  }

  int roundToLastTime(int currentTimeMillis, String mode) {
    switch (mode) {
      case "Day":
        return roundToNextDay(currentTimeMillis);
      case "Week":
        return roundToNextWeek(currentTimeMillis);
      case "Month":
        return roundToNextMonth(currentTimeMillis);
      default:
        throw ArgumentError(
            "Invalid mode. Supported modes are: 'Day', 'Week', 'Month'");
    }
  }
}
