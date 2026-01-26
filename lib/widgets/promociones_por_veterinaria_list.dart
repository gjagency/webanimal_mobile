import 'package:flutter/material.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/widgets/promociones_por_veterinaria.dart';

class PromocionesPorVeterinariaList extends StatelessWidget {
  final List<PromocionesPorVeterinaria> grupos;

  const PromocionesPorVeterinariaList({
    super.key,
    required this.grupos,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: grupos.length,
      itemBuilder: (context, index) {
        return PromocionesPorVeterinariaWidget(
          grupo: grupos[index],
        );
      },
    );
  }
}
