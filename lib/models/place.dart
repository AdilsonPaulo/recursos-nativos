import 'dart:io';
import 'package:f09_recursos_nativos/models/place_location.dart';

class Place {
  final String id;
  final String title;
  final PlaceLocation? location;
  final File image;
  final DateTime creationDate; // Novo atributo

  Place({
    required this.id,
    required this.title,
    this.location,
    required this.image,
    required this.creationDate, // Incluído no construtor
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location?.toJson(),
      'image': image.path,
      'creationDate': creationDate.toIso8601String(), // Incluído no JSON
    };
  }

  factory Place.fromJson(String id, Map<String, dynamic> json) {
  return Place(
    id: id,
    title: json['title'],
    location: json['location'] != null
        ? PlaceLocation.fromJson(json['location'])
        : null,
    image: File(json['image']),
    creationDate: DateTime.now(),
  );
}

}
