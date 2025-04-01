import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bus_tracking_screen.dart';
import '../services/route_service.dart';

class AvailableBusesScreen extends StatefulWidget {
  const AvailableBusesScreen({
    super.key,
    required this.startLocation,
    required this.endLocation,
  });

  final String startLocation;
  final String endLocation;

  @override
  State<AvailableBusesScreen> createState() => _AvailableBusesScreenState();
}

class _AvailableBusesScreenState extends State<AvailableBusesScreen> {
  final RouteService _routeService = RouteService();
  List<Map<String, dynamic>> _buses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    try {
      final buses = await _routeService.getAvailableBuses(
        widget.startLocation,
        widget.endLocation,
      );
      if (mounted) {
        setState(() {
          _buses = buses;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading buses: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          'Available Buses',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RouteInfoCard(
              startLocation: widget.startLocation,
              endLocation: widget.endLocation,
            ),
            const SizedBox(height: 24),
            Text(
              'Available Buses',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_buses.isEmpty)
              Center(
                child: Text(
                  'No buses available for this route',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF666666),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _buses.length,
                  itemBuilder: (context, index) {
                    final bus = _buses[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: BusCard(
                        busNumber: bus['busNumber'],
                        departureTime: bus['departureTime'],
                        arrivalTime: bus['arrivalTime'],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BusTrackingScreen(
                                busNumber: bus['busNumber'],
                                startLocation: widget.startLocation,
                                endLocation: widget.endLocation,
                                tripId: bus['tripId'],
                              ),
                            ),
                          );
                        },
                      ),
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

class RouteInfoCard extends StatelessWidget {
  final String startLocation;
  final String endLocation;

  const RouteInfoCard({
    super.key,
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
      child: Row(
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
    );
  }
}

class BusCard extends StatelessWidget {
  final String busNumber;
  final String departureTime;
  final String arrivalTime;
  final VoidCallback onTap;

  const BusCard({
    super.key,
    required this.busNumber,
    required this.departureTime,
    required this.arrivalTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
                    'Available',
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeInfo('Departure', departureTime),
                _buildTimeInfo('Arrival', arrivalTime),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}