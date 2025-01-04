import 'package:f09_recursos_nativos/models/place_location.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' show Placemark, placemarkFromCoordinates;

import '../screens/map_screen.dart';
import '../utils/location_util.dart';

class LocationInput extends StatefulWidget {
  final Function onSelectLocation;

  const LocationInput(this.onSelectLocation, {super.key});

  @override
  _LocationInputState createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  String? _previewImageUrl;
  String? _address;

  Future<void> _getCurrentUserLocation() async {
  final locData = await Location().getLocation();

  final staticMapImageUrl = LocationUtil.generateLocationPreviewImage(
      latitude: locData.latitude, longitude: locData.longitude);

  setState(() {
    _previewImageUrl = staticMapImageUrl;
  });

  await getAddress(locData.latitude!, locData.longitude!);

  PlaceLocation location = PlaceLocation(
    latitude: locData.latitude!,
    longitude: locData.longitude!,
    address: _address!,
  );
  
  widget.onSelectLocation(location);
}

  Future<void> _selectOnMap() async {
    final LatLng? selectedPosition = await Navigator.of(context).push(
      MaterialPageRoute(
          fullscreenDialog: true, builder: ((context) => MapScreen())),
    );
    if(selectedPosition == null) return;

    final staticMapImageUrl = LocationUtil.generateLocationPreviewImage(
        latitude: selectedPosition.latitude,
        longitude: selectedPosition.longitude);

    setState(() {
      _previewImageUrl = staticMapImageUrl;
    });

    await getAddress(selectedPosition.latitude, selectedPosition.longitude);

    PlaceLocation location = PlaceLocation(
    latitude: selectedPosition.latitude,
    longitude: selectedPosition.longitude,
    address: _address!,
  );
  
  widget.onSelectLocation(location);
  }

  Future<void> getAddress(double latitude, double longitude) async {
    try {
      Placemark place =
          (await placemarkFromCoordinates(latitude, longitude))[0];

      setState(() {
        _address = '${place.street}, ${place.locality}, ${place.country}';
      });
    } catch (e) {
      setState(() {
        _address = 'Erro ao buscar endereço.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 170,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              width: 1,
              color: Colors.grey,
            ),
          ),
          child: _previewImageUrl == null
              ? const Text('Localização não informada!')
              : Image.network(
                  _previewImageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.location_on),
              label: const Text('Atual'),
              onPressed: _getCurrentUserLocation,
            ),
            TextButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('Selecione no Mapa'),
              onPressed: _selectOnMap,
            ),
          ],
        )
      ],
    );
  }
}
