class PlaceLocation {
  final double latitude;
  final double longitude;
  String? address;
  String? phoneNumber;
  String? emailAddress;

  PlaceLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.phoneNumber,
    this.emailAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'phoneNumber': phoneNumber,
      'emailAddress': emailAddress,
    };
  }

  factory PlaceLocation.fromJson(Map<String, dynamic> json) {
    return PlaceLocation(
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      emailAddress: json['emailAddress'],
    );
  }
}
