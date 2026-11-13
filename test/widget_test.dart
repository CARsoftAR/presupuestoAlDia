import 'package:flutter_test/flutter_test.dart';
import 'package:presupuesto_al_dia/core/services/notification_service.dart';
import 'package:presupuesto_al_dia/features/agenda/models/cita_model.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_estado.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_item_model.dart';
import 'package:presupuesto_al_dia/features/presupuestos/models/presupuesto_model.dart';

void main() {
  test('Cálculo correcto de subtotales y modelos de presupuesto con items', () {
    final item1 = PresupuestoItemModel(
      descripcion: 'Cable 4mm',
      cantidad: 5,
      unidad: 'mts.',
      precioUnitario: 5000,
    );

    final item2 = PresupuestoItemModel(
      descripcion: '50 Tarugos y tornillos',
      cantidad: 1,
      unidad: 'global',
      precioUnitario: 30000,
    );

    expect(item1.subtotal, 25000.0);
    expect(item2.subtotal, 30000.0);

    final total = item1.subtotal + item2.subtotal;
    expect(total, 55000.0);

    final presupuesto = PresupuestoModel(
      numeroPresupuesto: '#P-0001',
      nombreCliente: 'Carlos Test',
      direccion: 'Av. Corrientes 1234',
      celular: '+549111111111',
      fechaEmision: DateTime(2026, 11, 13),
      estado: 'BORRADOR',
      descripcionTrabajo: 'CABLEAR TODO EL TECHO',
      total: total,
      items: [item1, item2],
    );

    expect(presupuesto.numero, '#P-0001');
    expect(presupuesto.total, 55000.0);
    expect(presupuesto.items.length, 2);
    expect(presupuesto.estadoEnum, EstadoPresupuesto.borrador);
    expect(PresupuestoModel.estadosValidos.length, 5);
  });

  test('Mapeo de los 5 estados obligatorios de presupuesto', () {
    for (final estadoStr in PresupuestoModel.estadosValidos) {
      final estado = EstadoPresupuesto.desdeString(estadoStr);
      expect(estado.clave, estadoStr);
      expect(estado.colorTexto, isNotNull);
      expect(estado.colorFondo, isNotNull);
    }
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
