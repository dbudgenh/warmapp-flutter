class SensorData {
  DateTime timestamp;
  double temperature;
  double humidity;
  double battery;

  SensorData(
      {required this.timestamp,
      required this.temperature,
      required this.humidity,
      required this.battery});

  @override
  String toString() {
    return 'SensorData($timestamp, $temperature°C, $humidity%, $battery%';
  }
}
