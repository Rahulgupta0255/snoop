import 'package:flutter/material.dart';
import 'package:shake/shake.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:sms_maintained/sms.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(SnoopApp());
}

class SnoopApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snoop - Stalker Alert',
      theme: ThemeData.dark(),  // Dark theme
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> alertLogs = [];

  @override
  void initState() {
    super.initState();
    loadAlerts();
    setupShakeDetector();
  }

  void setupShakeDetector() {
    ShakeDetector.autoStart(onPhoneShake: () {
      triggerAlert();
    });
  }

  Future<void> loadAlerts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      alertLogs = prefs.getStringList('alerts') ?? [];
    });
  }

  Future<void> sendEmergencySms() async {
    await Permission.sms.request();
    await Permission.location.request();

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    String locationUrl = "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

    String message = "🚨 SNOOP ALERT! Possible danger detected.\nLocation: $locationUrl";

    // Replace with your emergency contact number
    String phoneNumber = "7023315477";

    SmsSender sender = SmsSender();
    SmsMessage sms = SmsMessage(phoneNumber, message);
    sender.sendSms(sms);
  }

  Future<void> triggerAlert() async {
    String timestamp = DateFormat('yyyy-MM-dd – kk:mm:ss').format(DateTime.now());
    setState(() {
      alertLogs.add("🚨 Alert at $timestamp");
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('alerts', alertLogs);

    await sendEmergencySms();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("Alert Sent!", style: TextStyle(color: Colors.redAccent)),
        content: Text("Emergency SMS sent with your live location.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Snoop - Stalker Alert'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Shake your phone to trigger an emergency alert.\nYour location will be shared via SMS.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              icon: Icon(Icons.warning),
              label: Text('Send Manual Alert'),
              onPressed: triggerAlert,
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: alertLogs.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.history, color: Colors.orange),
                    title: Text(alertLogs[index], style: TextStyle(color: Colors.white)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
