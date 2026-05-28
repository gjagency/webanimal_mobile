import 'package:flutter/material.dart';
import 'package:mobile_app/service/location_service.dart';
import 'dart:async';

class LocationSearchPage extends StatefulWidget {
  const LocationSearchPage({super.key});

  @override
  State<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<LocationResult> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

void _onSearchChanged(String query) {
  setState(() {});

  if (_debounce?.isActive ?? false) {
    _debounce!.cancel();
  }

  final trimmed = query.trim();

  if (trimmed.isEmpty) {
    setState(() {
      _results = [];
      _isSearching = false;
      _hasSearched = false;
    });
    return;
  }

  setState(() {
    _isSearching = true;
    _hasSearched = true;
  });

  _debounce = Timer(
    const Duration(milliseconds: 500),
    () async {
      try {
        final results = await LocationService.searchLocation(
          trimmed,
        );

        if (!mounted) return;

        setState(() {
          _results = results;
          _isSearching = false;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _results = [];
          _isSearching = false;
        });
      }
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Buscar dirección...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
        if (_searchController.text.isNotEmpty)
        IconButton(
          icon: const Icon(
            Icons.clear,
            color: Colors.grey,
          ),
          onPressed: () {
            _searchController.clear();

            FocusScope.of(context).requestFocus(
              FocusNode(),
            );

            setState(() {
              _results = [];
              _isSearching = false;
              _hasSearched = false;
            });
          },
        ),
        ],
      ),
      body: Column(
        children: [
          Container(height: 1, color: Colors.grey[300]),
          if (_isSearching)
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: Colors.purple),
              ),
            )
         else if (_results.isEmpty && _hasSearched)
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No se encontraron resultados',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else if (_results.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.location_searching,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ingresa una dirección para buscar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.location_on, color: Colors.purple),
                        ),
                        title: Text(
                          result.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14),
                        ),
                       onTap: () async {
                          FocusScope.of(context).unfocus();

                          Navigator.pop(context, result);
                        },
                      ),
                      Divider(height: 1, color: Colors.grey[200]),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
