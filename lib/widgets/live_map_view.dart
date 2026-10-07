import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class LiveMapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final bool isEmergency;
  final String? label;
  final double height;
  final bool isInteractive;

  const LiveMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    this.accuracyMeters = 10.0,
    this.isEmergency = false,
    this.label,
    this.height = 240,
    this.isInteractive = true,
  });

  @override
  State<LiveMapView> createState() => _LiveMapViewState();
}

class _LiveMapViewState extends State<LiveMapView> {
  final MapController _mapController = MapController();

  void _recenter() {
    _mapController.move(
      LatLng(widget.latitude, widget.longitude),
      16.0,
    );
  }

  Future<void> _openExternalNavigation() async {
    final lat = widget.latitude;
    final lng = widget.longitude;
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    final geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng(SafePath+User)');

    try {
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch map app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = LatLng(widget.latitude, widget.longitude);
    final markerColor = widget.isEmergency ? AppColors.emergencyRed : AppColors.primaryBlue;

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isEmergency ? AppColors.emergencyRed : AppColors.primaryBlue,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Flutter Map Tile Layer
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: location,
                initialZoom: 16.0,
                interactionOptions: InteractionOptions(
                  flags: widget.isInteractive ? InteractiveFlag.all : InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.safepath.app.safepath',
                  maxZoom: 19,
                ),
                // Accuracy Circle
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: location,
                      radius: (widget.accuracyMeters).clamp(15.0, 60.0),
                      useRadiusInMeter: false,
                      color: markerColor.withValues(alpha: 0.2),
                      borderColor: markerColor,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                // Location Marker
                MarkerLayer(
                  markers: [
                    Marker(
                      point: location,
                      width: 50,
                      height: 50,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: markerColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: markerColor.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                            child: Icon(
                              widget.isEmergency ? Icons.warning_rounded : Icons.person_pin_circle_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Top Status Overlay
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isEmergency ? Icons.emergency : Icons.gps_fixed_rounded,
                      color: widget.isEmergency ? Colors.redAccent : Colors.lightBlueAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.label ?? 'GPS: ${widget.latitude.toStringAsFixed(5)}, ${widget.longitude.toStringAsFixed(5)} (±${widget.accuracyMeters.toInt()}m)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recenter & Navigation Buttons
            Positioned(
              bottom: 10,
              right: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'recenter_map_${widget.latitude}',
                    onPressed: _recenter,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryBlue,
                    tooltip: 'Recenter Map',
                    child: const Icon(Icons.my_location_rounded),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'nav_external_${widget.latitude}',
                    onPressed: _openExternalNavigation,
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    tooltip: 'Open in Google Maps / Navigation',
                    child: const Icon(Icons.directions_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
