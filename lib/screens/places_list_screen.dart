import 'dart:io';

import 'package:f09_recursos_nativos/provider/places_model.dart';
import 'package:f09_recursos_nativos/screens/place_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_routes.dart';

class PlacesListScreen extends StatefulWidget {
  @override
  _PlacesListScreenState createState() => _PlacesListScreenState();
}

class _PlacesListScreenState extends State<PlacesListScreen> {
  late Future<void> _placesFuture;

  @override
  void initState() {
    super.initState();
    _placesFuture = Provider.of<PlacesModel>(context, listen: false).loadPlaces();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _placesFuture = Provider.of<PlacesModel>(context, listen: false).loadPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Text(
          'Meus Lugares',
          style: TextStyle(color: Colors.white),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.PLACE_FORM);
            },
            icon: Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: Icon(Icons.sync, color: Colors.white,),
            onPressed: () async {
              await Provider.of<PlacesModel>(context, listen: false)
                  .loadPlaces();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sincronização concluída!')),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _placesFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar os lugares. Tente novamente.'),
            );
          } else {
            return Consumer<PlacesModel>(
              child: Center(
                child: Text('Nenhum local'),
              ),
              builder: (context, places, child) =>
                  places.itemsCount == 0
                      ? child!
                      : ListView.builder(
                          itemCount: places.itemsCount,
                          itemBuilder: (context, index) => ListTile(
                            leading: CircleAvatar(
                              backgroundImage: FileImage(
                                  places.itemByIndex(index).image),
                            ),
                            title: Text(places.itemByIndex(index).title),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => PlaceDetailScreen(
                                      place: places.itemByIndex(index)),
                                ),
                              );
                            },
                            onLongPress: () {
                              _confirmDelete(context, places, index);
                            },
                          ),
                        ),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, PlacesModel places, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir Local'),
        content: Text('Você tem certeza que deseja excluir este local?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Fecha o dialog
            },
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Fecha o dialog
              try {
                await Provider.of<PlacesModel>(context, listen: false)
                    .delete(places.itemByIndex(index).id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Local excluído com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao excluir o local: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

