import 'package:flutter/material.dart';
import 'package:mobile_app/service/reports_service.dart';

class ReportPopup {
  static Future<void> show(
    BuildContext context, {
    required UserReportType type,
    required String id,
    Function? onSent,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportSheet(type: type, id: id, onSent: onSent),
    );
  }
}

class ReportSheet extends StatefulWidget {
  final UserReportType type;
  final String id;
  Function? onSent;

  ReportSheet({super.key, required this.type, required this.id, this.onSent});

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final _controller = TextEditingController();
  bool _loading = false;
  bool _done = false;
  String? _error;

  bool get _isBlock =>
      widget.type == UserReportType.BLOQUEO_USUARIO ||
      widget.type == UserReportType.BLOQUEO_VETERINARIA;

  String get _title => switch (widget.type) {
    UserReportType.BLOQUEO_USUARIO => 'Bloquear usuario',
    UserReportType.BLOQUEO_VETERINARIA => 'Bloquear veterinaria',
    UserReportType.REPORTE_USUARIO => 'Reportar usuario',
    UserReportType.REPORTE_VETERINARIA => 'Reportar veterinaria',
    UserReportType.REPORTE_POSTEO => 'Reportar posteo',
    UserReportType.REPORTE_COMENTARIO => 'Reportar comentario',
    UserReportType.REPORTE_PROMOCION => 'Reportar promoción',
  };

  String get _description => _isBlock
      ? 'No verás más el contenido de esta persona y tampoco podrá interactuar con vos.'
      : 'Vamos a revisar tu reporte y te respondemos en menos de 24 horas.';

  String get _inputHint =>
      _isBlock ? 'Motivo del bloqueo (opcional)' : 'Contanos qué está pasando';

  String get _buttonLabel => _isBlock ? 'Bloquear' : 'Enviar reporte';

  Color get _accentColor =>
      _isBlock ? Colors.red : Theme.of(context).primaryColor;

  Future<void> _submit() async {
    final cause = _controller.text.trim();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ReportService.set(
        type: widget.type,
        value: widget.id,
        state:
            widget.type == UserReportType.BLOQUEO_USUARIO ||
                widget.type == UserReportType.BLOQUEO_VETERINARIA
            ? UserReportState.ACEPTADO
            : UserReportState.PENDIENTE,
        reason: cause,
      );
      setState(() => _done = true);
    } catch (_) {
      setState(() => _error = 'No se pudo enviar. Intentá de nuevo.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_done && widget.onSent != null) widget.onSent!();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(),
            )
          else if (_done)
            _buildDone()
          else
            _buildForm(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(
          _title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),

        // Descripción
        Text(
          _description,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 20),

        // Input causa
        TextField(
          controller: _controller,
          maxLines: 3,
          maxLength: 300,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: _inputHint,
            hintStyle: const TextStyle(color: Colors.black38),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Error
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),

        // Botón principal
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accentColor),
            onPressed: _submit,
            child: Text(_buttonLabel),
          ),
        ),
        const SizedBox(height: 8),

        // Cancelar
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDone() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isBlock ? Icons.block : Icons.check_circle_outline,
            size: 52,
            color: _isBlock ? Colors.red : Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            _isBlock ? 'Usuario bloqueado' : 'Reporte enviado',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _description,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Listo'),
            ),
          ),
        ],
      ),
    );
  }
}
