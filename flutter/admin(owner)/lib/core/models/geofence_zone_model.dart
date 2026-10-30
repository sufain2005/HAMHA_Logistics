import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class GeofenceZoneModel {
  final String id;
  final String name;
  final String category; // 'warehousing', 'commercial', 'freight_port'
  final Color color;
  final List<LatLng> polygonPoints;
  final LatLng centroid;
  final double radiusKm;
  final String restrictionNotes;

  const GeofenceZoneModel({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.polygonPoints,
    required this.centroid,
    this.radiusKm = 5.0,
    required this.restrictionNotes,
  });

  static List<GeofenceZoneModel> getDefaultZones() {
    return [
      GeofenceZoneModel(
        id: 'gf-01',
        name: 'Bhiwandi Logistics Hub',
        category: 'warehousing',
        color: const Color(0xFFF59E0B), // Amber
        centroid: const LatLng(19.2812, 73.0483),
        radiusKm: 6.5,
        restrictionNotes: 'Heavy Commercial Vehicles permitted 24/7. High Volume Freight Gate.',
        polygonPoints: const [
          LatLng(19.3100, 73.0200),
          LatLng(19.3200, 73.0700),
          LatLng(19.2600, 73.0900),
          LatLng(19.2450, 73.0300),
        ],
      ),
      GeofenceZoneModel(
        id: 'gf-02',
        name: 'BKC Financial & High-Value Corridor',
        category: 'commercial',
        color: const Color(0xFF38BDF8), // Light Blue
        centroid: const LatLng(19.0665, 72.8680),
        radiusKm: 3.0,
        restrictionNotes: 'Strict daytime EV/Van only. Heavy trucks prohibited 08:00 - 21:00.',
        polygonPoints: const [
          LatLng(19.0800, 72.8550),
          LatLng(19.0750, 72.8800),
          LatLng(19.0550, 72.8750),
          LatLng(19.0580, 72.8520),
        ],
      ),
      GeofenceZoneModel(
        id: 'gf-03',
        name: 'JNPT Port Container Zone',
        category: 'freight_port',
        color: const Color(0xFFDC2626), // Crimson Red
        centroid: const LatLng(18.9500, 72.9500),
        radiusKm: 8.0,
        restrictionNotes: 'Customs bonded gate pass required. Automated RFID weighbridge.',
        polygonPoints: const [
          LatLng(18.9800, 72.9200),
          LatLng(18.9900, 72.9800),
          LatLng(18.9100, 72.9900),
          LatLng(18.9200, 72.9100),
        ],
      ),
      GeofenceZoneModel(
        id: 'gf-04',
        name: 'Thane Central - Majiwada Cluster',
        category: 'warehousing',
        color: const Color(0xFF10B981), // Emerald
        centroid: const LatLng(19.2183, 72.9781),
        radiusKm: 4.0,
        restrictionNotes: 'Primary dispatch staging area for Northern MMR shipments.',
        polygonPoints: const [
          LatLng(19.2350, 72.9600),
          LatLng(19.2400, 73.0000),
          LatLng(19.1950, 73.0050),
          LatLng(19.2000, 72.9650),
        ],
      ),
    ];
  }
}

