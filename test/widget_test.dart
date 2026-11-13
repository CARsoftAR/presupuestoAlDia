import 'package:flutter_test/flutter_test.dart';
import 'package:presupuesto_al_dia/core/services/notification_service.dart';
import 'package:presupuesto_al_dia/core/utils/formatters.dart';
import 'package:presupuesto_al_dia/features/agenda/models/cita_model.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/material_item_model.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_model.dart';

void main() {
  test('Cálculo correcto de subtotales y modelos de presupuesto', () {
    final mat1 = MaterialItemModel(
      descripcion: 'Cable unipolar 2.5mm',
      cantidad: 50,
      unidad: 'mts.',
      precioUnitario: 1200,
    );

    final mat2 = MaterialItemModel(
      descripcion: 'Disyuntor bipolar 25A',
      cantidad: 2,
      unidad: 'un.',
      precioUnitario: 25000,
    );

    expect(mat1.subtotal, 60000.0);
    expect(mat2.subtotal, 50000.0);

    final total = mat1.subtotal + mat2.subtotal;
    expect(total, 110000.0);

    final presupuesto = PresupuestoModel(
      numeroPresupuesto: 'PRE-2026-0001',
      nombreCliente: 'Carlos Test',
      direccion: 'Av. Corrientes 1234',
      celular: '+549111111111',
      fechaEmision: DateTime(2026, 11, 13),
      descripcionTrabajo: 'Renovación de tablero general',
      total: total,
      materiales: [mat1, mat2],
    );

    expect(presupuesto.total, 110000.0);
    expect(presupuesto.materiales.length, 2);
    expect(Formatters.formatNumber(50), '50');
  });

  test('Modelo Cita y formateo de alarmas locales', () {
    final fechaVisita = DateTime(2026, 12, 1, 10, 30);
    final cita = Cita(
      id: 1,
      nombreCliente: 'Esteban Martínez',
      establecimiento: 'Panadería La Ideal',
      direccion: 'Av. Belgrano 250',
      celular: '+54 9 11 8888-9999',
      fechaHoraVisita: fechaVisita,
      minutosAlarma: 60,
    );

    expect(cita.tieneAlarmaActiva, isTrue);
    expect(cita.minutosAnticipacionAlarma, 60);

    final map = cita.toMap();
    expect(map['nombre_cliente'], 'Esteban Martínez');
    expect(map['minutos_anticipacion_alarma'], 60);

    final desdeMap = Cita.fromMap(map);
    expect(desdeMap.nombreCliente, 'Esteban Martínez');
    expect(desdeMap.minutosAlarma, 60);

    expect(NotificationService.formatearAnticipacion(30), '30 min antes');
    expect(NotificationService.formatearAnticipacion(60), '1 hora antes');
    expect(NotificationService.formatearAnticipacion(120), '2 horas antes');
    expect(NotificationService.formatearAnticipacion(0), 'Sin alarma');
  });
}
