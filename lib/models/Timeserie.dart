class TimeSerie {
  String eventType;
  int eventVersion;
  Context context;

  TimeSerie({
    required this.eventType,
    required this.eventVersion,
    required this.context,
  });

  factory TimeSerie.fromJson(Map<String, dynamic> json) {
    return TimeSerie(
      eventType: json['eventType'],
      eventVersion: int.parse(json['eventVersion']),
      context: Context.fromJson(json['context']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventType': eventType,
      'eventVersion': eventVersion,
      'context': context.toJson(),
    };
  }
}

class Context {
  String deviceType;
  String deviceMac;
  double temperature;
  double humidity;
  int battery;
  String scale;
  String timeOfSample;

  Context({
    required this.deviceType,
    required this.deviceMac,
    required this.temperature,
    required this.humidity,
    required this.battery,
    required this.scale,
    required this.timeOfSample,
  });

  factory Context.fromJson(Map<String, dynamic> json) {
    return Context(
      deviceType: json['deviceType'],
      deviceMac: json['deviceMac'],
      temperature: json['temperature'].toDouble(),
      humidity: json['humidity'].toDouble(),
      battery: json['battery'],
      scale: json['scale'],
      timeOfSample: json['timeOfSample'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceType': deviceType,
      'deviceMac': deviceMac,
      'temperature': temperature,
      'humidity': humidity,
      'battery': battery,
      'scale': scale,
      'timeOfSample': timeOfSample,
    };
  }
}
