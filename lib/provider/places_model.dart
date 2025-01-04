import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:f09_recursos_nativos/models/place_location.dart';
import 'package:flutter/material.dart';

import '../models/place.dart';
import '../utils/db_util.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class PlacesModel with ChangeNotifier {
  final _baseUrl = 'https://mini-projeto-v-8a0e6-default-rtdb.firebaseio.com/';
  List<Place> _items = [];

  List<Place> get items {
    return [..._items];
  }

  int get itemsCount {
    return _items.length;
  }

  Place itemByIndex(int index) {
    return _items[index];
  }

  Future<bool> hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  void addPlace(String title, File img, PlaceLocation location) async {
  try {
    final newPlace = Place(
      id: Random().nextDouble().toString(),
      title: title,
      creationDate: DateTime.now(),
      location: location,
      image: img,
    );

    await DbUtil.insert('places', {
      'id': newPlace.id,
      'title': newPlace.title,
      'creationDate': newPlace.creationDate.toIso8601String(),
      'image': newPlace.image.path,
      'location': newPlace.location?.toJson(),
    });

    // Requisição HTTP
    var response = await http.post(
      Uri.parse('$_baseUrl/places.json'),
      body: jsonEncode(newPlace.toJson()),
    );

    if (response.statusCode == 200) {
      final id = jsonDecode(response.body)['name'];

      _items.add(Place(
        id: id,
        title: newPlace.title,
        creationDate: newPlace.creationDate,
        location: newPlace.location,
        image: newPlace.image,
      ));

      notifyListeners();
    } else {
      throw Exception("Erro ao adicionar o lugar na requisição");
    }
  } catch (e) {
    print('Erro ao adicionar o lugar: $e');
  }
}


  Future<void> loadPlaces() async {
  try {
    if (await hasInternet()) {
      final response = await http.get(Uri.parse('$_baseUrl/places.json'));

      if (response.statusCode == 200) {

        Map<String, dynamic> placesJson = jsonDecode(response.body);

        List<Place> remotePlaces = placesJson.entries
            .where((entry) => entry.value != null)
            .map((entry) {
              try {
                final placeData = entry.value;
                final placeId = entry.key;
                return Place.fromJson(placeId, placeData);
              } catch (e) {
                print("Erro ao criar lugar com dados: $e");
                return null;
              }
            })
            .whereType<Place>()
            .toList()
          ..sort((a, b) => b.creationDate.compareTo(a.creationDate));
        final maxItems = remotePlaces.length < 10 ? remotePlaces.length : 10;
        remotePlaces = remotePlaces.sublist(0, maxItems);
        await DbUtil.clearTable('places');
        for (var place in remotePlaces) {
          await DbUtil.insert('places', place.toJson());
        }
        _items = remotePlaces;
        notifyListeners();
      } else {
        throw Exception("Erro ao buscar dados remotos");
      }
    } else {
      final dataList = await DbUtil.getData('places');
      _items = dataList.map((item) => Place.fromJson(item['id'], item)).toList();
      notifyListeners();
    }
  } catch (e) {
    print("Erro ao carregar os lugares: $e");

    final dataList = await DbUtil.getData('places');
    _items = dataList.map((item) => Place.fromJson(item['id'], item)).toList();
    notifyListeners();
  }
}



  Future<void> update(Place place) async {
  try {
    await DbUtil.update('places', place.toJson(), place.id);

    final response = await http.patch(
      Uri.parse('$_baseUrl/places/${place.id}.json'),
      body: jsonEncode(place.toJson()),
    );

    if (response.statusCode == 200) {
      final placeIndex = _items.indexWhere((item) => item.id == place.id);

      if (placeIndex >= 0) {
        _items[placeIndex] = Place(
          id: place.id,
          title: place.title,
          creationDate: place.creationDate,
          location: place.location,
          image: place.image,
        );

        notifyListeners();
      } else {
        throw Exception("Lugar não encontrado na lista para atualizar.");
      }
    } else {
      throw Exception(
          "Erro ao atualizar o lugar na requisição: ${response.statusCode}");
    }
  } catch (e) {
    print('Erro ao atualizar o lugar: $e');
  }
}



  Future<void> delete(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/places/$id.json'),
      );

      if (response.statusCode == 200) {
        await DbUtil.delete('places', id);
        _items.removeWhere((place) => place.id == id);
        notifyListeners();
      } else {
        throw Exception(
            "Erro ao deletar o lugar remoto: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erro ao deletar o lugar remoto: $e");
    }
  }

  Future<void> syncPlaces() async {
  try {
    final response = await http.get(Uri.parse('$_baseUrl/places.json'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> remoteData = jsonDecode(response.body);

      final localData = await DbUtil.getData('places');
      final remotePlaces = remoteData.entries
          .map((entry) => Place.fromJson(entry.key, entry.value))
          .toList()
        ..sort((a, b) => b.creationDate.compareTo(a.creationDate))
        ..sublist(0, 10);

      final localIds = localData.map((item) => item['id']).toSet();

      for (var place in remotePlaces) {
        if (!localIds.contains(place.id)) {
          await DbUtil.insert('places', place.toJson());
        } else {
          final localPlace = localData.firstWhere((item) => item['id'] == place.id);
          final localPlaceDate = DateTime.parse(localPlace['creationDate']);
          final remotePlaceDate = DateTime.parse(place.creationDate as String);

          if (remotePlaceDate.isAfter(localPlaceDate)) {
            await DbUtil.update('places', place.toJson(), place.id);
          }
        }
      }
      _items = remotePlaces;
      notifyListeners();
    } else {
      throw Exception("Erro ao buscar dados remotos: ${response.statusCode}");
    }
  } catch (e) {
    print("Erro ao sincronizar lugares: $e");
  }
}

}
