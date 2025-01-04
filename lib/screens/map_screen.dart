import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:f09_recursos_nativos/models/place_location.dart';

class MapScreen extends StatefulWidget {
  final PlaceLocation initialLocation;
  final bool isReadonly;

  MapScreen({super.key, 
    PlaceLocation? initialLocation,
    this.isReadonly = false,
  }) : initialLocation = initialLocation ??
            PlaceLocation(
              latitude: 37.419857,
              longitude: -122.078827,
              address: "Logo ali",
              phoneNumber: "4002-8922",
              emailAddress: "YudiTamashiro@gmail.com",
            );

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _pickedPosition;
  final TextEditingController _searchController = TextEditingController(); // Controlador do campo de pesquisa

  // Controlador do Google Maps
  late GoogleMapController _mapController;

  void _selectPosition(LatLng position) {
    setState(() {
      _pickedPosition = position;
    });
  }

  // Método para pesquisar o endereço
  Future<void> _searchAddress() async {
    String address = _searchController.text;
    if (address.isEmpty) return;

    try {
      // Usando geocoding para obter a localização a partir do endereço
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        setState(() {
          _pickedPosition = LatLng(locations[0].latitude, locations[0].longitude);
        });

        // Movendo a câmera para a nova posição
        _mapController.animateCamera(
          CameraUpdate.newLatLng(_pickedPosition!),
        );
      }
    } catch (e) {
      // Se ocorrer erro, exibe uma mensagem
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Endereço não encontrado")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecione...'),
        actions: <Widget>[
          if (!widget.isReadonly)
            IconButton(
              onPressed: _pickedPosition == null
                  ? null
                  : () {
                      Navigator.of(context).pop(_pickedPosition);
                    },
              icon: const Icon(Icons.check),
            ),
        ],
      ),
      body: Column(
        children: [
          // Campo de pesquisa
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Digite o endereço",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchAddress, // Ao pressionar o botão de pesquisa
                ),
              ),
            ),
          ),
          // Mapa
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.initialLocation.latitude,
                  widget.initialLocation.longitude,
                ),
                zoom: 13,
              ),
              onTap: widget.isReadonly ? null : _selectPosition,
              markers: _pickedPosition == null
                  ? {}
                  : {
                      Marker(
                        markerId: const MarkerId('p1'),
                        position: _pickedPosition!,
                      ),
                    },
            ),
          ),
        ],
      ),
    );
  }
}
