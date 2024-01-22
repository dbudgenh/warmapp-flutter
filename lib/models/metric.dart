enum Metric {
  temperature(name: "Temperature", metric: "°C"),
  humidity(name: "Humidity", metric: "%"),
  battery(name: "Battery", metric: "%");

  const Metric({required this.name, required this.metric});
  final String name;
  final String metric;
}
