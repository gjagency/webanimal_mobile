import 'package:flutter/material.dart';
import 'package:mobile_app/service/posts_service.dart';
import 'promocion_card.dart';

class PromocionesFeed extends StatelessWidget {
  final List<Promocion> promociones;
  final Future<void> Function() onRefresh;
  final VoidCallback onTap;

  const PromocionesFeed({
    super.key,
    required this.promociones,
    required this.onRefresh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (promociones.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tenés promociones activas',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
        itemCount: promociones.length,
        itemBuilder: (context, index) {
          final promo = promociones[index];
          return PromocionCard(
            promocion: promo,
            onTap: onTap,
          );
        },
      ),
    );
  }
}
