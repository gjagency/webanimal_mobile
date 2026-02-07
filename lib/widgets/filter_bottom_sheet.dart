import 'dart:convert';
import 'dart:ui';
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

class _FilterBottomSheetState extends State<FilterBottomSheet>
    with SingleTickerProviderStateMixin {
  late String? tempTypeId;
  late String? tempPetTypeId;
  late String? tempCityId;

  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    tempTypeId = widget.selectedTypeId;
    tempPetTypeId = widget.selectedPetTypeId;
    tempCityId = widget.selectedCityId;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final safeBottom = media.padding.bottom;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.55,
          maxChildSize: 0.96,
          expand: false,
          builder: (_, controller) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.only(bottom: keyboard),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                ),
                child: Column(
                  children: [
                    /// HANDLE
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    /// CONTENIDO SCROLL
                    Expanded(
                      child: SingleChildScrollView(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filtros',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 22),

                            /// TIPO POST
                            const Text(
                              'Tipo de Publicación',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.postTypes.map((type) {
                                final isSelected = tempTypeId == type.id;
                                return ChoiceChip(
                                  label: Text(type.name),
                                  selected: isSelected,
                                  onSelected: (v) => setState(() =>
                                      tempTypeId = v ? type.id : null),
                                  selectedColor: Colors.purple[100],
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            /// TIPO MASCOTA
                            const Text(
                              'Tipo de Mascota',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.petTypes.map((type) {
                                final isSelected = tempPetTypeId == type.id;
                                return ChoiceChip(
                                  label: Text(type.name),
                                  avatar: Icon(Icons.pets,
                                      size: 18,
                                      color: isSelected
                                          ? Colors.purple
                                          : Colors.black54),
                                  selected: isSelected,
                                  onSelected: (v) => setState(() =>
                                      tempPetTypeId = v ? type.id : null),
                                  selectedColor: Colors.purple[100],
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            /// CIUDAD
                            const Text(
                              'Ciudad',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            _buildCitySearch(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    /// BOTONES STICKY
                    Container(
                      padding:
                          EdgeInsets.fromLTRB(16, 10, 16, safeBottom + 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFEAEAEA)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isApplying
                                  ? null
                                  : () {
                                      setState(() {
                                        tempTypeId = null;
                                        tempPetTypeId = null;
                                        tempCityId = null;
                                      });
                                    },
                              child: const Text('Limpiar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _isApplying ? null : _applyFilters,
                              child: _isApplying
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Aplicar'),
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
        ),
      ),
    );
  }

  /// APPLY
  Future<void> _applyFilters() async {
    setState(() => _isApplying = true);

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    widget.onApply(tempTypeId, tempPetTypeId, tempCityId);
    Navigator.pop(context);
  }

  /// SEARCH CITY
  Widget _buildCitySearch() {
    return SearchAnchor(
      builder: (context, controller) {
        final data = tempCityId != null
            ? utf8.decode(base64.decode(tempCityId!)).split(":")
            : [];

        return InkWell(
          onTap: () => controller.openView(),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  tempCityId != null ? Colors.purple[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tempCityId != null
                    ? Colors.purple
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data.length == 3 ? data[2] : 'Seleccionar ciudad',
                  ),
                ),
                if (tempCityId != null)
                  GestureDetector(
                    onTap: () => setState(() => tempCityId = null),
                    child: const Icon(Icons.clear),
                  )
                else
                  const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        );
      },
      suggestionsBuilder: (context, controller) async {
        if (controller.text.length < 2) {
          return const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('Escribe al menos 2 caracteres'),
            )
          ];
        }

        final cities =
            await PostsService.searchCities(controller.text);

        if (cities.isEmpty) {
          return const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('No se encontraron ciudades'),
            )
          ];
        }

        return cities.map((c) {
          return ListTile(
            title: Text(c.ciudad),
            subtitle: Text('${c.estado}, ${c.pais}'),
            onTap: () {
              setState(() => tempCityId = c.id);
              controller.closeView(c.ciudad);
            },
          );
        }).toList();
      },
    );
  }
}
