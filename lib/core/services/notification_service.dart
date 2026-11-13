import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  NotificationService._internal();

  /// Inicializa zonas horarias y configuración nativa de notificaciones
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Inicializar base de datos de zonas horarias
      tz.initializeTimeZones();

      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final locationName = tz.timeZoneDatabase.locations.entries
          .firstWhere(
            (entry) => entry.value.currentTimeZone.offset == offset,
            orElse: () => tz.timeZoneDatabase.locations.entries.first,
          )
          .key;
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (e) {
      debugPrint('Advertencia: Ajuste de zona horaria local con fallback: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notificación de cita interactuada: ${response.payload}');
        },
      );
      _isInitialized = true;

      // Solicitar permisos en Android 13+ (POST_NOTIFICATIONS)
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error al inicializar plugin de notificaciones: $e');
    }
  }

  /// Programa la alarma exacta para una cita
  Future<void> programarAlarmaCita({
    required int citaId,
    required String cliente,
    required String direccion,
    required DateTime fechaHoraVisita,
    required int minutosAntes,
    String? establecimiento,
  }) async {
    // Si los minutos antes son 0 o negativos, significa que la alarma está apagada
    if (minutosAntes <= 0) {
      await cancelarAlarmaCita(citaId);
      return;
    }

    // Cancelar cualquier alarma previa para evitar duplicados
    await cancelarAlarmaCita(citaId);

    final notificationTime = fechaHoraVisita.subtract(Duration(minutes: minutosAntes));
    final now = DateTime.now();

    // Solo programar si la fecha resultante es futura
    if (!notificationTime.isAfter(now)) {
      debugPrint('La hora de la alarma ($notificationTime) ya transcurrió. No se programará.');
      return;
    }

    // Manejo seguro en plataformas desktop (Windows/Linux) donde zonedSchedule no esté soportado
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      debugPrint('Plataforma Desktop detectada: Alarma registrada de forma lógica para Cita #$citaId a las $notificationTime.');
      return;
    }

    try {
      final tzDateTime = tz.TZDateTime.from(notificationTime, tz.local);
      final String anticipacionStr = formatearAnticipacion(minutosAntes);
      final String lugarStr = (establecimiento != null && establecimiento.isNotEmpty)
          ? '$establecimiento ($direccion)'
          : direccion;

      const androidDetails = AndroidNotificationDetails(
        'citas_electricista_channel',
        'Recordatorios de Citas y Visitas',
        channelDescription: 'Alarmas programadas para visitas técnicas de Electricista Pro',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id: citaId,
        title: '⚡ Recordatorio de Visita ($anticipacionStr)',
        body: 'Visita con $cliente en $lugarStr',
        scheduledDate: tzDateTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'cita_$citaId',
      );

      debugPrint('Alarma programada con éxito para $notificationTime (Cita #$citaId)');
    } catch (e) {
      debugPrint('Manejo seguro: Error o no soportado al programar zonedSchedule: $e');
    }
  }

  /// Cancela la notificación programada asociada a un citaId
  Future<void> cancelarAlarmaCita(int citaId) async {
    try {
      await _notificationsPlugin.cancel(id: citaId);
      debugPrint('Alarma cancelada para Cita #$citaId');
    } catch (e) {
      debugPrint('Manejo seguro al cancelar notificación: $e');
    }
  }

  static String formatearAnticipacion(int minutos) {
    if (minutos <= 0) return 'Sin alarma';
    if (minutos < 60) return '$minutos min antes';
    if (minutos == 60) return '1 hora antes';
    if (minutos % 60 == 0) {
      final horas = minutos ~/ 60;
      return '$horas horas antes';
    }
    final horas = minutos ~/ 60;
    final resto = minutos % 60;
    return '${horas}h ${resto}m antes';
  }
}

