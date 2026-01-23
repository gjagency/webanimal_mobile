import 'package:flutter/material.dart';
import 'package:mobile_app/service/auth_service.dart';

class SpeedDial extends StatelessWidget {
  final VoidCallback? onCrearPromocion;
  final VoidCallback? onCrearPost;

  const SpeedDial({super.key, this.onCrearPromocion, this.onCrearPost});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🔹 Solo si es veterinaria
        if (AuthService.esVeterinaria && onCrearPromocion != null)
          FloatingActionButton(
            onPressed: onCrearPromocion,
            heroTag: 'promocion',
            tooltip: 'Crear Promoción',
            child: const Icon(Icons.local_offer_rounded),
          ),

        const SizedBox(height: 8),

        // Crear post (para todos)
        if (onCrearPost != null)
          FloatingActionButton(
            onPressed: onCrearPost,
            heroTag: 'post',
            tooltip: 'Crear Post',
            child: const Icon(Icons.post_add),
          ),
      ],
    );
  }
}
