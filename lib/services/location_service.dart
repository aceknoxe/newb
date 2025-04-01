import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<List<String>> getLocationSuggestions(String query) async {
    if (query.length < 2) return [];

    try {
      debugPrint('Fetching suggestions for query: $query');
      
      // Get both route locations and bus stops
      final routeResponse = await _supabaseClient
          .from('route')
          .select('start_location, stop_location')
          .or('start_location.ilike.%${query}%,stop_location.ilike.%${query}%')
          .limit(3);

      final stopResponse = await _supabaseClient
          .from('bus_stop')
          .select('name')
          .ilike('name', '%$query%')
          .order('stop_order', ascending: true)
          .limit(3);

      debugPrint('Route response: $routeResponse');
      debugPrint('Stop response: $stopResponse');

      // Combine and deduplicate locations
      final Set<String> locations = {};
      
      if (routeResponse != null) {
        for (final route in routeResponse as List) {
          locations.add(route['start_location'] as String);
          locations.add(route['stop_location'] as String);
        }
      }

      if (stopResponse != null) {
        for (final stop in stopResponse as List) {
          locations.add(stop['name'] as String);
        }
      }

      // Filter locations that contain the query and remove "Location " prefix
      final suggestions = locations
        .where((location) => location.toLowerCase().contains(query.toLowerCase()))
        .map((location) => location.replaceAll('Location ', ''))
        .take(5)
        .toList();

      debugPrint('Final suggestions: $suggestions');
      return suggestions;
      
    } catch (e) {
      debugPrint('Error fetching location suggestions: $e');
      return [];
    }
  }
}