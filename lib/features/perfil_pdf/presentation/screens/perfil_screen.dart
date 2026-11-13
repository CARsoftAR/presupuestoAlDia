import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:presupuesto_al_dia/core/theme/app_theme.dart';
import 'package:presupuesto_al_dia/core/widgets/glass_container.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/data/perfil_repository.dart';
import 'package:presupuesto_al_dia/features/perfil_pdf/models/perfil_model.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _perfilRepo = PerfilRepository();

  late TextEditingController _empresaCtrl;
  late TextEditingController _nombreCtrl;
  late TextEditingController _matriculaCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _mensajeCtrl;
  late TextEditingController _piePaginaCtrl;

  String? _rutaImagenCabecera;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _empresaCtrl = TextEditingController();
    _nombreCtrl = TextEditingController();
    _matriculaCtrl = TextEditingController();
    _direccionCtrl = TextEditingController();
    _telefonoCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _mensajeCtrl = TextEditingController();
    _piePaginaCtrl = TextEditingController();

    _loadPerfil();
  }

  Future<void> _loadPerfil() async {
    final perfil = await _perfilRepo.getPerfil();
    setState(() {
      _empresaCtrl.text = perfil.nombreEmpresa;
      _nombreCtrl.text = perfil.nombreElectricista;
      _matriculaCtrl.text = perfil.matricula;
      _direccionCtrl.text = perfil.direccion;
      _telefonoCtrl.text = perfil.telefono;
      _emailCtrl.text = perfil.email;
      _mensajeCtrl.text = perfil.cuerpoMensajeDefault;
      _piePaginaCtrl.text = perfil.piePagina;
      _rutaImagenCabecera = perfil.rutaImagenCabecera;
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'cabecera_logo_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
        final savedImage = await File(pickedFile.path).copy(p.join(appDir.path, fileName));

        setState(() {
          _rutaImagenCabecera = savedImage.path;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logo/Cabecera actualizada exitosamente'),
              backgroundColor: AppColors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar imagen: $e'),
              backgroundColor: AppColors.estadoCancelado,
            ),
          );
        }
      }
    }
  }

  void _removeImage() {
    setState(() {
      _rutaImagenCabecera = null;
    });
  }

  Future<void> _savePerfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final perfilActualizado = PerfilModel(
      id: 1,
      nombreEmpresa: _empresaCtrl.text.trim(),
      nombreElectricista: _nombreCtrl.text.trim(),
      matricula: _matriculaCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      rutaImagenCabecera: _rutaImagenCabecera,
      cuerpoMensajeDefault: _mensajeCtrl.text.trim(),
      piePagina: _piePaginaCtrl.text.trim(),
    );

    await _perfilRepo.savePerfil(perfilActualizado);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil y datos de PDF guardados con éxito'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _empresaCtrl.dispose();
    _nombreCtrl.dispose();
    _matriculaCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _mensajeCtrl.dispose();
    _piePaginaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Tarjeta de Cabecera / Logo
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Row(
                  children: [
                    Icon(Icons.brush_rounded, color: AppColors.orange, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Cabecera / Logo del PDF',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_rutaImagenCabecera != null && File(_rutaImagenCabecera!).existsSync()) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_rutaImagenCabecera!),
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.change_circle_outlined, size: 18),
                        label: const Text('Cambiar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.orange,
                          side: const BorderSide(color: AppColors.orange),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _removeImage,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Quitar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.estadoCancelado,
                          side: const BorderSide(color: AppColors.estadoCancelado),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.orange.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 44,
                          color: AppColors.orange.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Carga tu logotipo o membrete',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text('Elegir Imagen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Tarjeta de Datos del Electricista
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge_rounded, color: AppColors.green, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Datos del Profesional',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _empresaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de Fantasía o Empresa',
                    hintText: 'Ej. Instalaciones Eléctricas Morales',
                    prefixIcon: Icon(Icons.business_rounded, color: AppColors.textSecondary),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa tu nombre o el de tu empresa'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Electricista',
                    hintText: 'Ej. Juan Morales',
                    prefixIcon: Icon(Icons.person_rounded, color: AppColors.textSecondary),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa tu nombre completo'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _matriculaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Matrícula Profesional / Registro',
                    hintText: 'Ej. Mat. COPIME N° 45892',
                    prefixIcon: Icon(Icons.verified_rounded, color: AppColors.orange),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono / WhatsApp',
                    hintText: 'Ej. +54 9 11 5555-1234',
                    prefixIcon: Icon(Icons.phone_rounded, color: AppColors.green),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    hintText: 'Ej. electricista@correo.com',
                    prefixIcon: Icon(Icons.email_rounded, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _direccionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección o Zona de Cobertura',
                    hintText: 'Ej. CABA y Gran Buenos Aires',
                    prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.violet),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Tarjeta de Textos para PDF
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.text_snippet_rounded, color: AppColors.violet, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Textos por Defecto en Presupuestos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mensajeCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Cuerpo de Mensaje Predeterminado',
                    hintText: 'Texto formal introductorio que aparece en el PDF...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _piePaginaCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Pie de Página / Garantía / Condiciones',
                    hintText: 'Ej. Validez por 15 días. Garantía de 1 año en mano de obra...',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botón Guardar
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _savePerfil,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Guardando...' : 'Guardar Configuración'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
