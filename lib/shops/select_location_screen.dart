import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class SelectLocationScreen extends StatefulWidget {
  @override
  State<SelectLocationScreen> createState() =>
      _SelectLocationScreenState();
}

class _SelectLocationScreenState
    extends State<SelectLocationScreen> {
  LatLng selectedLatLng = LatLng(13.0827, 80.2707); // Chennai default
  String address = "Tap on map to select location";

  final TextEditingController searchController =
  TextEditingController();

  // 🔍 SEARCH PLACE (FREE - OpenStreetMap)
  Future<void> searchPlace(String query) async {
    final url =
        "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1";

    final res = await http.get(Uri.parse(url));

    if (res.statusCode == 200) {
      final data = json.decode(res.body);

      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);

        setState(() {
          selectedLatLng = LatLng(lat, lon);
        });

        getAddress(lat, lon);
      }
    }
  }

  // 📍 GET ADDRESS FROM LAT LNG
  Future<void> getAddress(double lat, double lng) async {
    try {
      final placemarks =
      await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        setState(() {
          address =
          "${p.name}, ${p.locality}, ${p.administrativeArea}";
        });
      }
    } catch (e) {
      address = "Location selected";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Location")),

      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search place...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    searchPlace(searchController.text);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // 🗺️ MAP
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: selectedLatLng,
                initialZoom: 13,
                onTap: (tapPos, latLng) {
                  setState(() {
                    selectedLatLng = latLng;
                  });

                  getAddress(latLng.latitude, latLng.longitude);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                  userAgentPackageName: 'com.example.untitled',

                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedLatLng,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on,
                          color: Colors.red, size: 40),
                    ),
                  ],
                )
              ],
            ),
          ),

          // 📍 ADDRESS + BUTTON
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                Text(address,
                    style: const TextStyle(fontSize: 14)),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      "lat": selectedLatLng.latitude,
                      "lng": selectedLatLng.longitude,
                      "address": address,
                    });
                  },
                  child: const Text("Confirm Location"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}