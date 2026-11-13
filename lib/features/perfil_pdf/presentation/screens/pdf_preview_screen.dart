import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:presupuesto_al_dia/core/theme/app_theme.dart';
import 'package:presupuesto_al_dia/core/widgets/glass_container.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_model.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/models/perfil_model.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/services/pdf_service.dart';

class PdfPreviewScreen extends StatelessWidget {
  final PresupuestoModel presupuesto;
  final PerfilModel perfil;

  const PdfPreviewScreen({
    super.key,
    required this.presupuesto,
    required this.perfil,
  });

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: Text('Presupuesto ${presupuesto.numeroPresupuesto}'),
        actions: [
          IconButton(
            tooltip: 'Enviar por WhatsApp',
            icon: const Icon(Icons.share, color: AppColors.green),
            onPressed: () async {
              await PdfService.instance.shareViaWhatsApp(
                presupuesto: presupuesto,
                perfil: perfil,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GlassContainer(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: AppColors.green, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          presupuesto.nombreCliente,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Listo para imprimir o enviar al cliente',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await PdfService.instance.shareViaWhatsApp(
                        presupuesto: presupuesto,
                        perfil: perfil,
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PdfPreview(
                  build: (format) => PdfService.instance.generatePresupuestoPdf(
                    presupuesto: presupuesto,
                    perfil: perfil,
                  ),
                  allowPrinting: true,
                  allowSharing: true,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  pdfFileName: 'Presupuesto_${presupuesto.numeroPresupuesto}.pdf',
                  actions: [
                    PdfPreviewAction(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: (context, build, pageFormat) async {
                        await PdfService.instance.shareViaWhatsApp(
                          presupuesto: presupuesto,
                          perfil: perfil,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

