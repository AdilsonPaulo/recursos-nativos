import 'package:f09_recursos_nativos/provider/places_model.dart';
import 'package:flutter/material.dart';
import 'package:f09_recursos_nativos/models/place.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceDetailScreen extends StatefulWidget {
  final Place place;

  PlaceDetailScreen({required this.place});

  @override
  _PlaceDetailScreenState createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  late TextEditingController addressController;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    addressController =
        TextEditingController(text: widget.place.location?.address ?? '');
    phoneController =
        TextEditingController(text: widget.place.location?.phoneNumber ?? '');
    emailController =
        TextEditingController(text: widget.place.location?.emailAddress ?? '');
  }

  @override
  void dispose() {
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        final result = await InternetAddress.lookup('google.com');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
      return false;
    } catch (e) {
      debugPrint("Erro ao verificar conexão: $e");
      return false;
    }
  }

  void _openPhoneDialer(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Não foi possível abrir o aplicativo de chamadas.';
    }
  }

  void _openEmailApp(String emailAddress) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Não foi possível abrir o aplicativo de e-mails.';
    }
  }

  void _openMapApp(double latitude, double longitude) async {
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      throw 'Sem conexão com a internet. Não é possível abrir o mapa.';
    }

    final Uri mapUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri);
    } else {
      throw 'Não foi possível abrir o aplicativo de mapas.';
    }
  }

  void _editDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom:
                MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: 'Endereço'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Telefone'),
                  inputFormatters: [
                        MaskedInputFormatter('(00) 0000-0000'),
                      ],
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      widget.place.location?.address = addressController.text;
                      widget.place.location?.phoneNumber = phoneController.text;
                      widget.place.location?.emailAddress =
                          emailController.text;
                    });
                    Provider.of<PlacesModel>(context, listen: false).update(widget.place);
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    elevation: 0,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Salvar Alterações'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasInternetConnection(),
      builder: (ctx, snapshot) {
        final hasInternet = snapshot.data ?? false;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.place.title),
            actions: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: _editDetails,
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.file(
                  widget.place.image,
                  fit: BoxFit.cover,
                  height: 250,
                  width: double.infinity,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Endereço:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.place.location?.address ?? 'Não disponível',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (widget.place.location?.phoneNumber != null)
                        GestureDetector(
                          onTap: () => _openPhoneDialer(
                              widget.place.location!.phoneNumber!),
                          child: Text(
                            "Telefone: ${widget.place.location?.phoneNumber}",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      if (widget.place.location?.emailAddress != null)
                        GestureDetector(
                          onTap: () => _openEmailApp(
                              widget.place.location!.emailAddress!),
                          child: Text(
                            "Email: ${widget.place.location?.emailAddress}",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        "Mapa:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      hasInternet &&
                              widget.place.location?.latitude != null &&
                              widget.place.location?.longitude != null
                          ? GestureDetector(
                              onTap: () => _openMapApp(
                                widget.place.location!.latitude!,
                                widget.place.location!.longitude!,
                              ),
                              child: Image.network(
                                'https://maps.googleapis.com/maps/api/staticmap?center=${widget.place.location!.latitude},${widget.place.location!.longitude}&zoom=16&size=600x300&maptype=roadmap&markers=color:red%7Clabel:L%7C${widget.place.location!.latitude},${widget.place.location!.longitude}&key=AIzaSyB6f5VuOXSr2X6qo4wzcmiAUDIyLF66kcU',
                                fit: BoxFit.cover,
                                height: 200,
                                width: double.infinity,
                              ),
                            )
                          : Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: Center(
                                child: Text(
                                  hasInternet
                                      ? 'Localização não disponível'
                                      : 'Sem conexão com a internet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
