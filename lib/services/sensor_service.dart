import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:warmapp/models/Sensordata.dart';
import 'package:warmapp/models/Timeserie.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  Map<String, String> getApiHeader() {
    const token =
        'b0d308b991cfd23731963bb2bbac42a330ec01adfdbe4229fc40e25432fa289b369679849b3dad1c05e64166e1943fb2';
    const secret = 'ae14fd6cd1d6f7630857c8cea2faec27';
    // Create nonce and timestamp
    var nonce = DateTime.now().millisecondsSinceEpoch.toString();
    var t = DateTime.now().millisecondsSinceEpoch;

    // Create the string to sign
    var stringToSign = '$token$t$nonce';
    var secretBytes = utf8.encode(secret);
    var signBytes = utf8.encode(stringToSign);

    // Create HMAC SHA256 signature
    var hmacSha256 = Hmac(sha256, secretBytes);
    var sign = hmacSha256.convert(signBytes);

    // Build the API header
    var apiHeader = {
      'Authorization': token,
      'Content-Type': 'application/json',
      'charset': 'utf8',
      't': t.toString(),
      'sign': base64.encode(sign.bytes),
      'nonce': nonce,
    };

    return apiHeader;
  }

  Future<List<TimeSerie>> getSensorData(String deviceId) async {
    List<TimeSerie> result = [];
    var url =
        Uri.parse("https://warmapp-server.onrender.com/sensorData/$deviceId");
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var sensorData = jsonDecode(response.body) as List;
      for (var data in sensorData) {
        result.add(TimeSerie.fromJson(data));
      }
      return result;
    } else {
      throw Exception('Failed to get data for $deviceId');
    }
  }

  Future<Map<String, String>> getDevices() async {
    var url = Uri.parse('https://api.switch-bot.com/v1.1/devices');
    var response = await http.get(url, headers: getApiHeader());
    // Check for status code 200
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      // Extracting deviceList and creating the map
      var deviceList = data['body']['deviceList'] as List;
      Map<String, String> devices = {};

      for (var device in deviceList) {
        String deviceId = device['deviceId'];
        String deviceName = device['deviceName'];
        if (deviceName.toLowerCase().contains("hub")) {
          continue;
        }
        devices[deviceId] = device['deviceName'];
      }

      return devices;
    } else {
      throw Exception('Failed to load devices');
    }
  }
}
