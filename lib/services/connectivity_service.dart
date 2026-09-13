import 'dart:async';
import 'dart:io' show InternetAddress, SocketException;
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Servicio para detectar el estado de conexión a internet en tiempo real
/// y verificar activamente si la conexión es estable y capaz de alcanzar la nube.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  bool _initialized = false;

  /// Inicializa el listener de conectividad
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final initialResults = await _connectivity.checkConnectivity();
      _isOnline = await _evaluateConnection(initialResults);
    } catch (e) {
      debugPrint('[ConnectivityService] Error comprobando conectividad inicial: $e');
      _isOnline = true; // Asumir optimista
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      final hasConnection = await _evaluateConnection(results);
      if (_isOnline != hasConnection) {
        _isOnline = hasConnection;
        debugPrint('[ConnectivityService] Estado de conexión cambió: ${_isOnline ? "ONLINE" : "OFFLINE"}');
        _connectivityController.add(_isOnline);
      }
    });
  }

  /// Evalúa los resultados de red y realiza una prueba activa si hay interfaz de red
  Future<bool> _evaluateConnection(List<ConnectivityResult> results) async {
    final hasNetworkInterface = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);

    if (!hasNetworkInterface) {
      return false;
    }

    return await checkGoodConnection();
  }

  /// Realiza una prueba activa de acceso a internet real (DNS probe / ping con timeout)
  Future<bool> checkGoodConnection() async {
    if (kIsWeb) {
      // En entorno Web, los navegadores manejan el stack de red y dart:io no está disponible
      try {
        final results = await _connectivity.checkConnectivity();
        return results.any((r) => r != ConnectivityResult.none);
      } catch (_) {
        return true;
      }
    }

    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Permite forzar o simular el estado de conexión (útil para pruebas unitarias)
  @visibleForTesting
  void setOnlineForTesting(bool online) {
    _isOnline = online;
    _connectivityController.add(online);
  }

  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
