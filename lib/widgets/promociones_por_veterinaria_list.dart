import 'package:flutter/material.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'package:mobile_app/widgets/promociones_por_veterinaria.dart';

class PromocionesPorVeterinariaList extends StatelessWidget {
  final List<PromocionesPorVeterinaria> grupos;
  final void Function(int veterinariaId)? onGroupEmpty;

  const PromocionesPorVeterinariaList({
    super.key,
    required this.grupos,
    this.onGroupEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: grupos.length,
      itemBuilder: (context, index) {
        final grupo = grupos[index];
        return PromocionesPorVeterinariaWidget(
          key: ValueKey(grupo.veterinariaId),
          grupo: grupo,
          onEmpty: onGroupEmpty == null
              ? null
              : () => onGroupEmpty!(grupo.veterinariaId),
        );
      },
    );
  }
}
