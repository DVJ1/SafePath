import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/esp32_config.dart';
import '../models/stick_sensor_data.dart';
import '../providers/app_state_provider.dart';
import '../providers/settings_provider.dart';

class HardwareSettingsScreen extends StatefulWidget {
  const HardwareSettingsScreen({super.key});

  @override
  State<HardwareSettingsScreen> createState() => _HardwareSettingsScreenState();
}

class _HardwareSettingsScreenState extends State<HardwareSettingsScreen> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late TextEditingController _pathController;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final config = Provider.of<SettingsProvider>(context, listen: false).esp32Config;
    _ipController = TextEditingController(text: config.ipAddress);
    _portController = TextEditingController(text: config.port.toString());
    _pathController = TextEditingController(text: config.endpointPath);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _testEsp32Connection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 80;
    final path = _pathController.text.trim();
    final url = 'http://$ip:$port$path';

    final stopwatch = Stopwatch()..start();
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      stopwatch.stop();

      if (res.statusCode == 200) {
        setState(() {
          _isTesting = false;
          _testSuccess = true;
          _testResult = 'Connection Successful (${stopwatch.elapsedMilliseconds}ms)!\nResponse: ${res.body.length > 80 ? "${res.body.substring(0, 80)}..." : res.body}';
        });
      } else {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = 'Server returned HTTP ${res.statusCode}';
        });
      }
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult = 'Failed to connect to ESP32 at $url: $e\nCheck that phone is on same Wi-Fi network as the ESP32 stick.';
      });
    }
  }

  void _saveConfig(SettingsProvider settings) {
    final cur = settings.esp32Config;
    final updated = cur.copyWith(
      ipAddress: _ipController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 80,
      endpointPath: _pathController.text.trim(),
    );
    settings.updateEsp32Config(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ESP32 Configuration Saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final appState = Provider.of<AppStateProvider>(context);
    final sensor = appState.sensorData;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 Hardware Config'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hardware Mode Switcher Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Hardware Simulation Mode',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          settings.esp32Config.isSimulationMode
                              ? 'Active (Simulates HC-SR04, MPU6050 & Moisture)'
                              : 'Disabled (Connecting to physical ESP32 Wi-Fi stick)',
                        ),
                        value: settings.esp32Config.isSimulationMode,
                        onChanged: (val) {
                          settings.setSimulationMode(val);
                        },
                      ),
                      if (settings.esp32Config.isSimulationMode) ...[
                        const Divider(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Active Simulation Scenario:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: SimulationScenario.values.map((sc) {
                            final isSel = settings.esp32Config.currentScenario == sc;
                            return ChoiceChip(
                              label: Text(sc.name),
                              selected: isSel,
                              onSelected: (val) {
                                if (val) appState.setSimulationScenario(sc);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Physical ESP32 Wi-Fi Network Settings
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.wifi_tethering_rounded, color: AppColors.primaryBlue),
                          SizedBox(width: 8),
                          Text(
                            'ESP32 Wi-Fi Connection Settings',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          labelText: 'ESP32 IP Address',
                          hintText: 'e.g. 192.168.4.1 or 192.168.1.50',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.router_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _portController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Port',
                                hintText: '80',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _pathController,
                              decoration: const InputDecoration(
                                labelText: 'Endpoint Path',
                                hintText: '/sensors',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isTesting ? null : _testEsp32Connection,
                              icon: _isTesting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.network_check_rounded),
                              label: const Text('Test Connection'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _saveConfig(settings),
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('Save Settings'),
                            ),
                          ),
                        ],
                      ),
                      if (_testResult != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _testSuccess
                                ? AppColors.safeGreen.withValues(alpha: 0.15)
                                : AppColors.emergencyRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _testSuccess ? AppColors.safeGreen : AppColors.emergencyRed,
                            ),
                          ),
                          child: Text(
                            _testResult!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _testSuccess ? AppColors.safeGreen : AppColors.emergencyRed,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Live Real-Time Sensor Telemetry Visualizer
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.monitor_heart_rounded, color: AppColors.primaryBlueLight),
                          SizedBox(width: 8),
                          Text(
                            'Live Sensor Telemetry Stream',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildMetricRow('Ultrasonic Distance (HC-SR04)', '${sensor.distanceCm.toStringAsFixed(1)} cm', sensor.obstacleSeverity == ObstacleSeverity.clear ? AppColors.safeGreen : AppColors.emergencyRed),
                      _buildMetricRow('Surface Moisture Sensor', '${sensor.moistureLevelPercent.toStringAsFixed(1)}% (${sensor.surfaceHazard.name})', sensor.surfaceHazard == SurfaceHazardType.normalDry ? AppColors.safeGreen : AppColors.warningOrange),
                      _buildMetricRow('MPU6050 Accelerometer', 'X: ${sensor.ax.toStringAsFixed(1)}, Y: ${sensor.ay.toStringAsFixed(1)}, Z: ${sensor.az.toStringAsFixed(1)} m/s²', Colors.lightBlue),
                      _buildMetricRow('MPU6050 Gyroscope', 'X: ${sensor.gx.toStringAsFixed(1)}, Y: ${sensor.gy.toStringAsFixed(1)}, Z: ${sensor.gz.toStringAsFixed(1)} °/s', Colors.lightBlue),
                      _buildMetricRow('Fall Detection State', sensor.fallDetected ? 'TRIGGERED / ALARM' : 'NORMAL / UPRIGHT', sensor.fallDetected ? AppColors.emergencyRed : AppColors.safeGreen),
                      _buildMetricRow('Stick Battery & Voltage', '${sensor.batteryPercent}% (${sensor.batteryVoltage.toStringAsFixed(2)}V)', sensor.batteryPercent < 20 ? AppColors.emergencyRed : AppColors.safeGreen),
                      const SizedBox(height: 12),
                      const Text(
                        'Raw JSON Telemetry Packet:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black45 : const Color(0xFFE9ECEF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          const JsonEncoder.withIndent('  ').convert(sensor.toJson()),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey))),
          Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      ),
    );
  }
}
