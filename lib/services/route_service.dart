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
            bus_stop (*),
            trip!inner (route (route_stops (bus_stop (*))))
          ''')
          .eq('trip_id', tripId)
          .order('actual_time', ascending: false)
          .limit(1);

      if (transmitterResponse == null || (transmitterResponse as List).isEmpty) {
        return {};
      }

      final lastLocation = transmitterResponse[0];
      final currentStopOrder = lastLocation['stop_order'];
      final routeStops = lastLocation['trip']['route']['route_stops'] as List;
      final totalStops = routeStops.length;
      
      debugPrint('Current stop order: $currentStopOrder, Total stops: $totalStops');
      
      // Get the last stop from route_stops
      final lastRouteStop = routeStops.lastWhere(
        (stop) => stop['sequence'] == totalStops,
        orElse: () => null,
      );
      
      debugPrint('Last route stop found: ${lastRouteStop != null}');
      
      // Check if we're at the last stop or first stop
      bool isLastStop = currentStopOrder == totalStops;
      bool isFirstStop = currentStopOrder == 1;
      
      debugPrint('Is last stop: $isLastStop, Is first stop: $isFirstStop');
      
      // Set direction immediately if at last or first stop
      if (isLastStop) {
        debugPrint('Bus is at last stop. Setting direction to 180 degrees for return journey.');
        return {
          'stopName': lastLocation['bus_stop']['name'],
          'actualTime': lastLocation['actual_time'],
          'stopOrder': currentStopOrder,
          'totalStops': totalStops,
          'direction': 180, // Force 180 degrees at last stop for return journey
          'isLastStop': true,
        };
      } else if (isFirstStop) {
        return {
          'stopName': lastLocation['bus_stop']['name'],
          'actualTime': lastLocation['actual_time'],
          'stopOrder': currentStopOrder,
          'totalStops': totalStops,
          'direction': 0, // Force 0 degrees at first stop
        };
      }
      
      // For intermediate stops, determine direction based on previous location
      bool isForward;
      final previousLocationResponse = await _supabaseClient
          .from('transmitter_data')
          .select()
          .eq('trip_id', tripId)
          .order('actual_time', ascending: false)
          .range(1, 1);
      
      debugPrint('Previous location data found: ${previousLocationResponse != null && previousLocationResponse.isNotEmpty}');
      
      if (previousLocationResponse != null && previousLocationResponse.isNotEmpty) {
        final prevStopOrder = previousLocationResponse[0]['stop_order'];
        isForward = currentStopOrder > prevStopOrder;
        debugPrint('Previous stop order: $prevStopOrder, Current stop order: $currentStopOrder');
        debugPrint('Direction determined from previous location: ${isForward ? "forward (0°)" : "return (180°)"}');
      } else {
        // If no previous data, assume direction based on position in route
        isForward = currentStopOrder < (totalStops / 2);
        debugPrint('No previous location data. Assuming direction based on route position.');
        debugPrint('Current position relative to route: ${isForward ? "first half (forward)" : "second half (return)"}');
      }
      
      final direction = isForward ? 0 : 180;
      
      return {
        'stopName': lastLocation['bus_stop']['name'],
        'actualTime': lastLocation['actual_time'],
        'stopOrder': currentStopOrder,
        'totalStops': totalStops,
        'direction': direction,
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
      // Find routes that contain both stops in their sequence
      final routeResponse = await _supabaseClient
          .from('route')
          .select('''
            route_id,
            route_stops!inner (stop_order, bus_stop!inner (name))
          ''');


      if (routeResponse == null || (routeResponse as List).isEmpty) {
        debugPrint('No routes found');
        return [];
      }

      // Filter routes that contain all the required stops in correct sequence
      final validRoutes = (routeResponse as List).where((route) {
        final routeStops = (route['route_stops'] as List)..sort((a, b) => ((a['stop_order'] as num?) ?? 0).compareTo((b['stop_order'] as num?) ?? 0));
        final stopNames = routeStops.map((stop) => stop['bus_stop']['name'].toString().toLowerCase()).toList();
        final startIdx = stopNames.indexWhere((name) => name.contains(startLocation.toLowerCase()));
        final endIdx = stopNames.indexWhere((name) => name.contains(endLocation.toLowerCase()));
        
        return startIdx != -1 && endIdx != -1 && startIdx < endIdx;
      }).toList();

      if (validRoutes.isEmpty) {
        debugPrint('No route found between $startLocation and $endLocation');
        return [];
      }

      final routeId = validRoutes[0]['route_id'];

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
        // Get all stops for this route in sequence order
        final routeStops = (validRoutes[0]['route_stops'] as List);
        routeStops.sort((a, b) => (a['stop_order'] as num).compareTo(b['stop_order'] as num));
        final allStops = routeStops.map((stop) => stop['bus_stop']['name']).toList();

        return {
          'busNumber': trip['bus_master']['name'],
          'departureTime': trip['start_time'],
          'arrivalTime': trip['end_time'],
          'busId': trip['bus_master']['bus_id'],
          'tripId': trip['trip_id'],
          'allStops': allStops, // Include all stops in the route
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching available buses: $e');
      return [];
    }
  }
}