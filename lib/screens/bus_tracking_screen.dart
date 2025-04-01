import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/route_service.dart';
import 'dart:async';

class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({
    super.key,
    required this.busNumber,
    required this.startLocation,
    required this.endLocation,
    required this.tripId,
  });

  final String busNumber;
  final String startLocation;
  final String endLocation;
  final String tripId;

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  final RouteService _routeService = RouteService();
  Map<String, dynamic> _currentLocation = {};
  bool _isLoading = true;
  List<Map<String, dynamic>> _busStops = [];
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _loadBusLocation();
    _loadBusStops();
    _startLocationUpdates();
  }

  Future<void> _loadBusLocation() async {
    try {
      final location = await _routeService.getCurrentBusLocation(widget.tripId);
      if (mounted) {
        setState(() {
          _currentLocation = location;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading bus location: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBusStops() async {
    try {
      final stops = await _routeService.getBusStops(widget.tripId);
      if (mounted) {
        setState(() {
          _busStops = stops;
        });
      }
    } catch (e) {
      debugPrint('Error loading bus stops: $e');
    }
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadBusLocation();
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Track Bus',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            BusInfoCard(
              busNumber: widget.busNumber,
              startLocation: widget.startLocation,
              endLocation: widget.endLocation,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Location',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: Size.infinite,
                            painter: RouteMapPainter(
                              busStops: _busStops,
                              currentLocation: _currentLocation,
                            ),
                          ),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RouteMapPainter extends CustomPainter {
  final List<Map<String, dynamic>> busStops;
  final Map<String, dynamic> currentLocation;

  RouteMapPainter({
    required this.busStops,
    required this.currentLocation,
  });

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    final other = oldDelegate as RouteMapPainter;
    return busStops.length != other.busStops.length ||
           currentLocation.toString() != other.currentLocation.toString();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5CB338)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final stopPaint = Paint()
      ..color = const Color(0xFF666666)
      ..style = PaintingStyle.fill;

    final currentLocationPaint = Paint()
      ..color = const Color(0xFF5CB338)
      ..style = PaintingStyle.fill;

    final double padding = 40;
    final double availableHeight = size.height - (padding * 2);
    final double stopRadius = 8;
    final double currentLocationRadius = 12;
    final double lineX = size.width * 0.2; // Moved line to 20% from left

    // Draw the vertical route line
    canvas.drawLine(
      Offset(lineX, padding),
      Offset(lineX, size.height - padding),
      paint,
    );

    if (busStops.isEmpty) return;

    final stopSpacing = busStops.length > 1 
        ? availableHeight / (busStops.length - 1)
        : availableHeight;

    // Draw bus stops
    for (int i = 0; i < busStops.length; i++) {
      final stopY = padding + (stopSpacing * i);
      final stopCenter = Offset(lineX, stopY);

      // Draw stop circle with white background
      canvas.drawCircle(
        stopCenter,
        stopRadius + 2,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(stopCenter, stopRadius, stopPaint);

      // Draw stop name with background
      final textPainter = TextPainter(
        text: TextSpan(
          text: busStops[i]['name'],
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Position text to the right of the line with more spacing
      final textX = lineX + 32;
      final textY = stopY - (textPainter.height / 2);

      // Draw text background
      final textBackground = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          textX - 8,
          textY - 4,
          textPainter.width + 16,
          textPainter.height + 8,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        textBackground,
        Paint()..color = Colors.white,
      );

      textPainter.paint(canvas, Offset(textX, textY));

      // Draw current location indicator
      if (currentLocation.isNotEmpty && 
          currentLocation['stopName'] == busStops[i]['name']) {
        // Outer glow effect
        for (var j = 3; j > 0; j--) {
          canvas.drawCircle(
            stopCenter,
            currentLocationRadius + (j * 4),
            Paint()
              ..color = const Color(0xFF5CB338).withOpacity(0.1 * j)
              ..style = PaintingStyle.fill,
          );
        }

        // Inner circle (current location)
        canvas.drawCircle(
          stopCenter,
          currentLocationRadius,
          currentLocationPaint,
        );

        // Draw current time with background
        if (currentLocation['actualTime'] != null) {
          final timeTextPainter = TextPainter(
            text: TextSpan(
              text: 'Last updated: ${_formatTime(currentLocation['actualTime'])}',
              style: const TextStyle(
                color: Color(0xFF5CB338),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          timeTextPainter.layout();

          final timeBackground = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              textX - 8,
              textY + textPainter.height + 4,
              timeTextPainter.width + 16,
              timeTextPainter.height + 8,
            ),
            const Radius.circular(4),
          );
          canvas.drawRRect(
            timeBackground,
            Paint()..color = const Color(0xFF5CB338).withOpacity(0.1),
          );

          timeTextPainter.paint(
            canvas,
            Offset(textX, textY + textPainter.height + 8),
          );
        }
      }
    }
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }
      return time;
    } catch (e) {
      debugPrint('Error parsing time: $e');
      return 'Invalid time';
    }
  }
}

class BusInfoCard extends StatelessWidget {
  final String busNumber;
  final String startLocation;
  final String endLocation;

  const BusInfoCard({
    super.key,
    required this.busNumber,
    required this.startLocation,
    required this.endLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                busNumber,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5CB338).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'On Route',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5CB338),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF5CB338),
                  ),
                  Container(
                    width: 2,
                    height: 30,
                    color: const Color(0xFF5CB338),
                  ),
                  const Icon(
                    Icons.location_searching,
                    color: Color(0xFF5CB338),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startLocation,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      endLocation,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}