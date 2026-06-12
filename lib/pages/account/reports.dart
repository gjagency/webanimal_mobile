import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/service/reports_service.dart';

class PageReportsSettings extends StatefulWidget {
  const PageReportsSettings({super.key});

  @override
  State<PageReportsSettings> createState() => _PageReportsSettingsState();
}

class _PageReportsSettingsState extends State<PageReportsSettings>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Reportes y bloqueos'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black45,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Reportes'),
            Tab(text: 'Bloqueos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ReportList(), _BlockList()],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Lista de Reportes
// ─────────────────────────────────────────────
class _ReportList extends StatefulWidget {
  const _ReportList();

  @override
  State<_ReportList> createState() => _ReportListState();
}

class _ReportListState extends State<_ReportList>
    with AutomaticKeepAliveClientMixin {
  final List<UserReport> _items = [];
  bool _loading = true;
  bool _hasMore = true;
  String? _error;
  int _skip = 0;
  static const int _take = 20;

  final _reportTypes = [
    UserReportType.REPORTE_USUARIO,
    UserReportType.REPORTE_POSTEO,
    UserReportType.REPORTE_COMENTARIO,
    UserReportType.REPORTE_VETERINARIA,
    UserReportType.REPORTE_PROMOCION,
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _items.clear();
        _skip = 0;
        _hasMore = true;
        _error = null;
      });
    }

    setState(() => _loading = true);

    try {
      // Traemos todos los tipos de reporte (no bloqueos)
      final results = await ReportService.get(take: _take, skip: _skip);
      final filtered = results
          .where((r) => _reportTypes.contains(r.type))
          .toList();

      setState(() {
        _items.addAll(filtered);
        _skip += _take;
        _hasMore = results.length == _take;
      });
    } catch (_) {
      setState(() => _error = 'No se pudieron cargar los reportes.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return _ErrorView(message: _error!, onRetry: () => _load(refresh: true));
    }

    if (_items.isEmpty) {
      return const _EmptyView(
        icon: Icons.flag_outlined,
        message: 'No hiciste ningún reporte todavía.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _items.length) {
            _load();
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _ReportTile(report: _items[i]);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Lista de Bloqueos
// ─────────────────────────────────────────────
class _BlockList extends StatefulWidget {
  const _BlockList();

  @override
  State<_BlockList> createState() => _BlockListState();
}

class _BlockListState extends State<_BlockList>
    with AutomaticKeepAliveClientMixin {
  final List<UserReport> _items = [];
  bool _loading = true;
  bool _hasMore = true;
  String? _error;
  int _skip = 0;
  static const int _take = 20;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _items.clear();
        _skip = 0;
        _hasMore = true;
        _error = null;
      });
    }

    setState(() => _loading = true);

    try {
      final results = await ReportService.get(
        tipo: UserReportType.BLOQUEO_USUARIO,
        take: _take,
        skip: _skip,
      );

      setState(() {
        _items.addAll(results);
        _skip += _take;
        _hasMore = results.length == _take;
      });
    } catch (_) {
      setState(() => _error = 'No se pudieron cargar los bloqueos.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _unblock(UserReport report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desbloquear'),
        content: const Text('¿Querés desbloquear a este usuario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Desbloquear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ReportService.set(
        type: report.type,
        value: report.value,
        state: UserReportState.CANCELADO,
      );
      setState(() => _items.remove(report));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo desbloquear.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return _ErrorView(message: _error!, onRetry: () => _load(refresh: true));
    }

    if (_items.isEmpty) {
      return const _EmptyView(
        icon: Icons.block,
        message: 'No bloqueaste a ningún usuario.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _items.length) {
            _load();
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _BlockTile(
            report: _items[i],
            onUnblock: () => _unblock(_items[i]),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tile de reporte
// ─────────────────────────────────────────────
class _ReportTile extends StatelessWidget {
  final UserReport report;
  const _ReportTile({required this.report});

  String get _typeLabel => switch (report.type) {
    UserReportType.REPORTE_USUARIO => 'Usuario',
    UserReportType.REPORTE_POSTEO => 'Posteo',
    UserReportType.REPORTE_COMENTARIO => 'Comentario',
    UserReportType.REPORTE_VETERINARIA => 'Veterinaria',
    UserReportType.REPORTE_PROMOCION => 'Promoción',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_outlined, color: Colors.orange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reporte de $_typeLabel',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                if (report.type == UserReportType.REPORTE_COMENTARIO)
                  Text(
                    report.targetDetail['body'],
                    style: const TextStyle(fontSize: 14),
                  )
                else if (report.type == UserReportType.REPORTE_POSTEO)
                  Text(
                    report.targetDetail['body'] ?? "",
                    style: const TextStyle(fontSize: 14),
                  )
                else if (report.type == UserReportType.REPORTE_PROMOCION)
                  Text(
                    report.targetDetail['titulo'] ?? "",
                    style: const TextStyle(fontSize: 14),
                  )
                else
                  Text(report.target, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  report.createdAt.toLocal().toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          _StateBadge(state: report.state),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tile de bloqueo
// ─────────────────────────────────────────────
class _BlockTile extends StatelessWidget {
  final UserReport report;
  final VoidCallback onUnblock;
  const _BlockTile({required this.report, required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: Colors.red, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (report.type == UserReportType.BLOQUEO_USUARIO)
                  Text(
                    report.targetDetail['username'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  )
                else
                  Text(
                    report.target,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  report.createdAt.toLocal().toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onUnblock,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Badge de estado
// ─────────────────────────────────────────────
class _StateBadge extends StatelessWidget {
  final UserReportState state;
  const _StateBadge({required this.state});

  Color get _color => switch (state) {
    UserReportState.PENDIENTE => Colors.orange,
    UserReportState.ACEPTADO => Colors.green,
    UserReportState.RECHAZADO => Colors.red,
    UserReportState.CANCELADO => Colors.grey,
  };

  String get _label => switch (state) {
    UserReportState.PENDIENTE => 'Pendiente',
    UserReportState.ACEPTADO => 'Aceptado',
    UserReportState.RECHAZADO => 'Rechazado',
    UserReportState.CANCELADO => 'Cancelado',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.black12),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.black45, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: const TextStyle(color: Colors.black45, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
