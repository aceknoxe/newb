import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RouteService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<Map<String, dynamic>> getCurrentBusLocation(String tripId) async {
    try {
      final transmitterResponse = await _supabaseClient
          .from('transmitter_data')
          .select('''
            *,
            bus_stop (*)
          ''')
          .eq('trip_id', tripId)
          .order('actual_time', ascending: false)
          .limit(1);

      if (transmitterResponse == null || (transmitterResponse as List).isEmpty) {
        return {};
      }

      final lastLocation = transmitterResponse[0];
      return {
        'stopName': lastLocation['bus_stop']['name'],
        'actualTime': lastLocation['actual_time'],
      };
    } catch (e) {
      debugPrint('Error fetching current bus location: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getBusStops(String tripId) async {
    try {
      final stopsResponse = await _supabaseClient
          .from('trip')
          .select('''
            *,
            route!inner (route_stops (bus_stop (*)))
          ''')
          .eq('trip_id', tripId)
          .single();

      if (stopsResponse == null || stopsResponse['route'] == null) {
        return [];
      }

      final routeStops = stopsResponse['route']['route_stops'] as List;
      return routeStops.map((stop) {
        return {
          'name': stop['bus_stop']['name'],
          'sequence': stop['sequence'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading bus stops: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableBuses(
    String startLocation,
    String endLocation,
  ) async {
    try {
      // Find the route_id for the given locations
      final routeResponse = await _supabaseClient
          .from('route')
          .select()
          .or('start_location.eq.${startLocation},start_location.eq.Location ${startLocation}')
          .or('stop_location.eq.${endLocation},stop_location.eq.Location ${endLocation}')
          .limit(1);

      if (routeResponse == null || (routeResponse as List).isEmpty) {
        debugPrint('No route found between $startLocation and $endLocation');
        return [];
      }

      final routeId = routeResponse[0]['route_id'];

      // Then, get all trips for this route
      final tripResponse = await _supabaseClient
          .from('trip')
          .select('''
            trip_id,
            start_time,
            end_time,
            bus_master!trip_bus_id_fkey (
              bus_id,
              name
            )
          ''')
          .eq('route_id', routeId);

      return (tripResponse as List).map((trip) {
        return {
          'busNumber': trip['bus_master']['name'],
          'departureTime': trip['start_time'],
          'arrivalTime': trip['end_time'],
          'busId': trip['bus_master']['bus_id'],
          'tripId': trip['trip_id'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching available buses: $e');
      return [];
    }
  }
}