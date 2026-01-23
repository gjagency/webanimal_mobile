import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_app/service/posts_service.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? selectedTypeId;
  final String? selectedPetTypeId;
  final String? selectedCityId;
  final List<PostType> postTypes;
  final List<PetType> petTypes;
  final bool hasLocation;
  final Function(String?, String?, String?) onApply;

  const FilterBottomSheet({
    super.key,
    this.selectedTypeId,
    this.selectedPetTypeId,
    this.selectedCityId,
    required this.postTypes,
    required this.petTypes,
    required this.hasLocation,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? tempTypeId;
  late String? tempPetTypeId;
  late String? tempCityId;

  @override
  void initState() {
    super.initState();
    tempTypeId = widget.selectedTypeId;
    tempPetTypeId = widget.selectedPetTypeId;
    tempCityId = widget.selectedCityId;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Tipo de post
                const Text(
                  'Tipo de Publicación',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.postTypes.map((type) {
                    final isSelected = tempTypeId == type.id;
                    return ChoiceChip(
                      label: Text(type.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => tempTypeId = selected ? type.id : null);
                      },
                      selectedColor: Colors.purple[100],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.purple : Colors.black87,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Tipo de mascota
                const Text(
                  'Tipo de Mascota',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.petTypes.map((type) {
                    final isSelected = tempPetTypeId == type.id;
                    return ChoiceChip(
                      label: Text(type.name),
                      avatar: Icon(
                        Icons.pets,
                        size: 18,
                        color: isSelected ? Colors.purple : Colors.black54,
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(
                          () => tempPetTypeId = selected ? type.id : null,
                        );
                      },
                      selectedColor: Colors.purple[100],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.purple : Colors.black87,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Ciudad
                const Text(
                  'Ciudad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildCitySearch(),

                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            tempTypeId = null;
                            tempPetTypeId = null;
                            tempCityId = null;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Limpiar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApply(tempTypeId, tempPetTypeId, tempCityId);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitySearch() {
    return SearchAnchor(
      builder: (BuildContext context, SearchController controller) {
        final data = tempCityId != null
            ? utf8.decode(base64.decode(tempCityId!)).split(":")
            : [];

        return Container(
          decoration: BoxDecoration(
            color: tempCityId != null ? Colors.purple[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tempCityId != null ? Colors.purple[300]! : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => controller.openView(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: tempCityId != null ? Colors.purple : Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data.length == 3 ? data[2] : 'Seleccionar ciudad',
                        style: TextStyle(
                          fontSize: 15,
                          color: tempCityId != null ? Colors.purple[900] : Colors.grey[600],
                          fontWeight: tempCityId != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (tempCityId != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        color: Colors.purple,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() => tempCityId = null);
                          controller.clear();
                        },
                      )
                    else
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey[600],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) async {
        if (controller.text.length < 2) {
          return [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    'Escribe al menos 2 caracteres',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ];
        }

        try {
          final cities = await PostsService.searchCities(controller.text);
          if (cities.isEmpty) {
            return [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.search_off, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      'No se encontraron ciudades',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ];
          }

          return cities.map((city) {
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_city, color: Colors.purple, size: 20),
              ),
              title: Text(
                city.ciudad,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('${city.estado}, ${city.pais}'),
              onTap: () {
                setState(() {
                  tempCityId = city.id;
                });
                controller.closeView(city.ciudad);
              },
            );
          }).toList();
        } catch (e) {
          return [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 12),
                  Text(
                    'Error al buscar ciudades',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ];
        }
      },
    );
  }
}
