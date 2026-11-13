import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:presupuesto_al_dia/core/utils/formatters.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_model.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/models/perfil_model.dart';

class PdfService {
  static final PdfService instance = PdfService._internal();
  PdfService._internal();

  /// Genera los bytes del PDF en formato A4 profesional
  Future<Uint8List> generatePresupuestoPdf({
    required PresupuestoModel presupuesto,
    required PerfilModel perfil,
  }) async {
    final pdf = pw.Document();

    // Intentar cargar la imagen de cabecera si existe
    pw.MemoryImage? headerImage;
    if (perfil.rutaImagenCabecera != null && perfil.rutaImagenCabecera!.isNotEmpty) {
      try {
        final file = File(perfil.rutaImagenCabecera!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          headerImage = pw.MemoryImage(bytes);
        }
      } catch (e) {
        debugPrint('Error al cargar imagen de cabecera para PDF: $e');
      }
    }

    final PdfColor primaryColor = PdfColor.fromHex('#FF6B00');
    final PdfColor secondaryColor = PdfColor.fromHex('#00D084');
    final PdfColor darkColor = PdfColor.fromHex('#1E1B2E');
    final PdfColor lightGray = PdfColor.fromHex('#F4F5F7');
    final PdfColor borderGray = PdfColor.fromHex('#D0D5DD');
    final PdfColor textGray = PdfColor.fromHex('#475467');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => _buildFooter(context, perfil, textGray),
        build: (context) => [
          // 1. Cabecera (Logo / Empresa y Número de Presupuesto)
          _buildHeader(
            presupuesto: presupuesto,
            perfil: perfil,
            headerImage: headerImage,
            primaryColor: primaryColor,
            darkColor: darkColor,
            lightGray: lightGray,
            borderGray: borderGray,
          ),
          pw.SizedBox(height: 18),

          // 2. Información del Cliente
          _buildClientSection(
            presupuesto: presupuesto,
            darkColor: darkColor,
            lightGray: lightGray,
            borderGray: borderGray,
          ),
          pw.SizedBox(height: 18),

          // 3. Cuerpo del mensaje / introducción (si existe)
          if (presupuesto.cuerpoMensaje.isNotEmpty) ...[
            pw.Text(
              presupuesto.cuerpoMensaje,
              style: pw.TextStyle(
                fontSize: 10,
                color: textGray,
                lineSpacing: 2,
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // 4. Sección Destacada: Tareas / Qué hay que hacer
          _buildTasksSection(
            descripcion: presupuesto.descripcionTrabajo,
            primaryColor: primaryColor,
            lightGray: lightGray,
          ),
          pw.SizedBox(height: 20),

          // 5. Tabla de Materiales y Costos
          _buildMaterialsTable(
            materiales: presupuesto.materiales,
            total: presupuesto.total,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            darkColor: darkColor,
            lightGray: lightGray,
            borderGray: borderGray,
          ),
          pw.SizedBox(height: 24),

          // 6. Condiciones y Firma
          _buildSignaturesAndTerms(
            perfil: perfil,
            validezDias: presupuesto.validezDias,
            textGray: textGray,
            borderGray: borderGray,
          ),
        ],
      ),
    );

    return await pdf.save();
  }

  pw.Widget _buildHeader({
    required PresupuestoModel presupuesto,
    required PerfilModel perfil,
    required pw.MemoryImage? headerImage,
    required PdfColor primaryColor,
    required PdfColor darkColor,
    required PdfColor lightGray,
    required PdfColor borderGray,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Datos del Electricista / Logo
        pw.Expanded(
          flex: 6,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (headerImage != null)
                pw.Container(
                  height: 60,
                  alignment: pw.Alignment.centerLeft,
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Image(headerImage, fit: pw.BoxFit.contain),
                ),
              pw.Text(
                perfil.nombreEmpresa.isNotEmpty
                    ? perfil.nombreEmpresa
                    : perfil.nombreElectricista,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: darkColor,
                ),
              ),
              if (perfil.nombreElectricista.isNotEmpty &&
                  perfil.nombreEmpresa != perfil.nombreElectricista)
                pw.Text(
                  perfil.nombreElectricista,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              if (perfil.matricula.isNotEmpty)
                pw.Text(
                  'Matrícula: ${perfil.matricula}',
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              pw.SizedBox(height: 4),
              if (perfil.direccion.isNotEmpty)
                pw.Text('Dirección: ${perfil.direccion}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              if (perfil.telefono.isNotEmpty)
                pw.Text('Tel: ${perfil.telefono}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              if (perfil.email.isNotEmpty)
                pw.Text('Email: ${perfil.email}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        // Recuadro Presupuesto
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightGray,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: borderGray),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'PRESUPUESTO',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  presupuesto.numeroPresupuesto,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: darkColor,
                  ),
                ),
                pw.Divider(color: borderGray, thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Fecha:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(Formatters.formatDate(presupuesto.fechaEmision),
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Validez:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('${presupuesto.validezDias} días',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: _getPdfEstadoColor(presupuesto.estado),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    presupuesto.estado.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildClientSection({
    required PresupuestoModel presupuesto,
    required PdfColor darkColor,
    required PdfColor lightGray,
    required PdfColor borderGray,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: borderGray),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DATOS DEL CLIENTE',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: darkColor,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      const pw.TextSpan(
                        text: 'Cliente: ',
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                      pw.TextSpan(
                        text: presupuesto.nombreCliente,
                        style: pw.TextStyle(
                            fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              if (presupuesto.celular.isNotEmpty)
                pw.Expanded(
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        const pw.TextSpan(
                          text: 'Teléfono / Móvil: ',
                          style:
                              pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                        pw.TextSpan(
                          text: presupuesto.celular,
                          style: pw.TextStyle(
                              fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (presupuesto.direccion.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.RichText(
              text: pw.TextSpan(
                children: [
                  const pw.TextSpan(
                    text: 'Ubicación / Domicilio: ',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                  pw.TextSpan(
                    text: presupuesto.direccion,
                    style: pw.TextStyle(
                        fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildTasksSection({
    required String descripcion,
    required PdfColor primaryColor,
    required PdfColor lightGray,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border(
          left: pw.BorderSide(color: primaryColor, width: 4),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TAREAS Y TRABAJOS A REALIZAR',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            descripcion,
            style: const pw.TextStyle(
              fontSize: 10,
              lineSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMaterialsTable({
    required List<dynamic> materiales,
    required double total,
    required PdfColor primaryColor,
    required PdfColor secondaryColor,
    required PdfColor darkColor,
    required PdfColor lightGray,
    required PdfColor borderGray,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DETALLE DE MATERIALES Y MANO DE OBRA',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: darkColor,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: borderGray, width: 0.5),
            bottom: pw.BorderSide(color: borderGray, width: 1),
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.2), // Cantidad
            1: const pw.FlexColumnWidth(5.0), // Descripción
            2: const pw.FlexColumnWidth(1.2), // Unidad
            3: const pw.FlexColumnWidth(2.3), // P. Unitario
            4: const pw.FlexColumnWidth(2.3), // Subtotal
          },
          children: [
            // Cabecera de la tabla
            pw.TableRow(
              decoration: pw.BoxDecoration(color: darkColor),
              children: [
                _buildTableCell('Cant.', isHeader: true, align: pw.TextAlign.center),
                _buildTableCell('Descripción / Ítem', isHeader: true),
                _buildTableCell('Unidad', isHeader: true, align: pw.TextAlign.center),
                _buildTableCell('P. Unitario', isHeader: true, align: pw.TextAlign.right),
                _buildTableCell('Subtotal', isHeader: true, align: pw.TextAlign.right),
              ],
            ),
            // Filas de materiales
            ...materiales.map((m) {
              return pw.TableRow(
                children: [
                  _buildTableCell(
                    Formatters.formatNumber(m.cantidad),
                    align: pw.TextAlign.center,
                  ),
                  _buildTableCell(m.descripcion),
                  _buildTableCell(
                    m.unidad,
                    align: pw.TextAlign.center,
                  ),
                  _buildTableCell(
                    Formatters.formatCurrency(m.precioUnitario),
                    align: pw.TextAlign.right,
                  ),
                  _buildTableCell(
                    Formatters.formatCurrency(m.subtotal),
                    align: pw.TextAlign.right,
                    isBold: true,
                  ),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 12),
        // Fila destacada del TOTAL
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'TOTAL:  ',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  Formatters.formatCurrency(total),
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8.5,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _buildSignaturesAndTerms({
    required PerfilModel perfil,
    required int validezDias,
    required PdfColor textGray,
    required PdfColor borderGray,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (perfil.piePagina.isNotEmpty) ...[
          pw.Text(
            'TÉRMINOS Y CONDICIONES:',
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            perfil.piePagina,
            style: pw.TextStyle(fontSize: 8, color: textGray),
          ),
          pw.SizedBox(height: 18),
        ],
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Forma de pago: A convenir',
                    style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Trabajo bajo normativa AEA / COPIME',
                    style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 140,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: borderGray, width: 1),
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  perfil.nombreElectricista,
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  perfil.matricula,
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context, PerfilModel perfil, PdfColor textGray) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado con PresupuestoAlDía • 100% Offline',
            style: pw.TextStyle(fontSize: 7.5, color: textGray),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 7.5, color: textGray),
          ),
        ],
      ),
    );
  }

  PdfColor _getPdfEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'BORRADOR':
        return PdfColor.fromHex('#9E9E9E');
      case 'PENDIENTE':
        return PdfColor.fromHex('#FF9F1C');
      case 'EMITIDO':
        return PdfColor.fromHex('#2EC4B6');
      case 'CANCELADO':
        return PdfColor.fromHex('#E71D36');
      case 'ACEPTADO':
        return PdfColor.fromHex('#00D084');
      default:
        return PdfColor.fromHex('#6C757D');
    }
  }

  /// Imprime o abre el diálogo nativo de impresión / vista previa
  Future<void> previewOrPrintPdf({
    required PresupuestoModel presupuesto,
    required PerfilModel perfil,
  }) async {
    final pdfBytes = await generatePresupuestoPdf(
      presupuesto: presupuesto,
      perfil: perfil,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Presupuesto_${presupuesto.numeroPresupuesto}.pdf',
    );
  }

  /// Comparte el PDF directamente vía WhatsApp u otras aplicaciones instaladas
  Future<void> shareViaWhatsApp({
    required PresupuestoModel presupuesto,
    required PerfilModel perfil,
  }) async {
    final pdfBytes = await generatePresupuestoPdf(
      presupuesto: presupuesto,
      perfil: perfil,
    );

    final cleanFileName = 'Presupuesto_${presupuesto.numeroPresupuesto}.pdf'
        .replaceAll(RegExp(r'[^\w\.-]'), '_');

    final message = '''
⚡ *Presupuesto Eléctrico: ${presupuesto.numeroPresupuesto}*
👤 *Cliente:* ${presupuesto.nombreCliente}
📋 *Trabajo:* ${presupuesto.descripcionTrabajo}
💰 *Total:* ${Formatters.formatCurrency(presupuesto.total)}
📅 *Validez:* ${presupuesto.validezDias} días

Adjunto el documento formal en PDF con el detalle de materiales y mano de obra.
_Generado por ${perfil.nombreEmpresa}_
''';

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(tempDir.path, cleanFileName);
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      await SharePlus.instance.share(
        ShareParams(
          text: message,
          files: [XFile(file.path, mimeType: 'application/pdf', name: cleanFileName)],
          subject: 'Presupuesto ${presupuesto.numeroPresupuesto} - ${presupuesto.nombreCliente}',
        ),
      );
    } catch (e) {
      debugPrint('Fallback share con Printing: $e');
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: cleanFileName,
      );
    }
  }
}
