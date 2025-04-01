import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/location_service.dart';
import 'available_buses_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final LocationService _locationService = LocationService();
  final TextEditingController _startLocationController = TextEditingController();
  final TextEditingController _endLocationController = TextEditingController();
  List<String> _startLocationSuggestions = [];
  List<String> _endLocationSuggestions = [];
  bool _showStartSuggestions = false;
  bool _showEndSuggestions = false;

  @override
  void dispose() {
    _startLocationController.dispose();
    _endLocationController.dispose();
    super.dispose();
  }

  void _onStartLocationChanged(String value) async {
    // If empty value was passed from suggestion selection, just hide suggestions
    if (value.isEmpty) {
      setState(() {
        _showStartSuggestions = false;
      });
      return;
    }

    // Don't search for very short queries
    if (value.length < 2) {
      setState(() {
        _startLocationSuggestions = [];
        _showStartSuggestions = false;
      });
      return;
    }

    try {
      final suggestions = await _locationService.getLocationSuggestions(value);
      if (mounted) {  // Check if widget is still mounted
        setState(() {
          _startLocationSuggestions = suggestions;
          _showStartSuggestions = suggestions.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error in start location suggestions: $e');
      if (mounted) {
        setState(() {
          _startLocationSuggestions = [];
          _showStartSuggestions = false;
        });
      }
    }
  }

  void _onEndLocationChanged(String value) async {
    // If empty value was passed from suggestion selection, just hide suggestions
    if (value.isEmpty) {
      setState(() {
        _showEndSuggestions = false;
      });
      return;
    }

    // Don't search for very short queries
    if (value.length < 2) {
      setState(() {
        _endLocationSuggestions = [];
        _showEndSuggestions = false;
      });
      return;
    }

    try {
      final suggestions = await _locationService.getLocationSuggestions(value);
      if (mounted) {  // Check if widget is still mounted
        setState(() {
          _endLocationSuggestions = suggestions;
          _showEndSuggestions = suggestions.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error in end location suggestions: $e');
      if (mounted) {
        setState(() {
          _endLocationSuggestions = [];
          _showEndSuggestions = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where would\nyou like to go?',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 40),
                LocationInput(
                  label: 'Starting Location',
                  hintText: 'Enter your starting point',
                  icon: Icons.location_on_outlined,
                  controller: _startLocationController,
                  onChanged: _onStartLocationChanged,
                  suggestions: _startLocationSuggestions,
                  showSuggestions: _showStartSuggestions,
                ),
                const SizedBox(height: 20),
                LocationInput(
                  label: 'Destination',
                  hintText: 'Where to?',
                  icon: Icons.location_searching,
                  controller: _endLocationController,
                  onChanged: _onEndLocationChanged,
                  suggestions: _endLocationSuggestions,
                  showSuggestions: _showEndSuggestions,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      final startLocation = _startLocationController.text.trim();
                      final endLocation = _endLocationController.text.trim();

                      if (startLocation.isEmpty || endLocation.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please enter both starting and destination locations',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AvailableBusesScreen(
                            startLocation: startLocation,
                            endLocation: endLocation,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5CB338),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Search Buses',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LocationInput extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final Function(String) onChanged;
  final List<String> suggestions;
  final bool showSuggestions;

  const LocationInput({
    super.key,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.controller,
    required this.onChanged,
    required this.suggestions,
    required this.showSuggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
              TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFFAAAAAA),
                  ),
                  prefixIcon: Icon(
                    icon,
                    color: const Color(0xFF5CB338),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              if (showSuggestions && suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.25,
                  ),
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
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        title: Text(
                          suggestions[index],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        onTap: () {
                          controller.text = suggestions[index];
                          controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: controller.text.length),
                          );
                          onChanged('');
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}