import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/time_block.dart';
import '../models/todo_item.dart';
import 'supabase_config.dart';

/// Servicio centralizado para autenticación y operaciones de base de datos con Supabase.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Cliente de Supabase
  SupabaseClient? get client {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Inicializa la conexión con Supabase si las credenciales son válidas.
  Future<bool> initialize() async {
    if (_initialized) return true;
    if (!SupabaseConfig.isConfigured) {
      debugPrint('[SupabaseService] Credenciales no configuradas. Modo offline.');
      return false;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      _initialized = true;
      debugPrint('[SupabaseService] Inicializado correctamente.');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Error al inicializar: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // Autenticación
  // ──────────────────────────────────────────────

  /// Usuario actualmente autenticado
  User? get currentUser => client?.auth.currentUser;

  /// Indica si hay una sesión activa
  bool get isAuthenticated => currentUser != null;

  /// Stream para escuchar cambios en el estado de autenticación
  Stream<AuthState>? get authStateChanges => client?.auth.onAuthStateChange;

  /// Registro de usuario con correo y contraseña
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final supa = client;
    if (supa == null) {
      throw Exception('Supabase no está inicializado o configurado.');
    }
    return await supa.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  /// Inicio de sesión con correo y contraseña
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final supa = client;
    if (supa == null) {
      throw Exception('Supabase no está inicializado o configurado.');
    }
    return await supa.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Cierre de sesión
  Future<void> signOut() async {
    final supa = client;
    if (supa == null) return;
    await supa.auth.signOut();
  }

  /// Envío de correo de recuperación de contraseña
  Future<void> resetPasswordForEmail(String email) async {
    final supa = client;
    if (supa == null) {
      throw Exception('Supabase no está inicializado.');
    }
    await supa.auth.resetPasswordForEmail(email.trim());
  }

  // ──────────────────────────────────────────────
  // Base de Datos: Bloques de Tiempo (TimeBlocks)
  // ──────────────────────────────────────────────

  /// Obtiene todos los bloques de tiempo del usuario desde Supabase
  Future<List<TimeBlock>> fetchTimeBlocks() async {
    final supa = client;
    final user = currentUser;
    if (supa == null || user == null) return [];

    try {
      final response = await supa
          .from('time_blocks')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: true);

      final List<TimeBlock> list = [];
      for (final row in response) {
        list.add(TimeBlock.fromSupabaseMap(Map<String, dynamic>.from(row)));
      }
      return list;
    } catch (e) {
      debugPrint('[SupabaseService] Error al obtener time_blocks: $e');
      return [];
    }
  }

  /// Inserta o actualiza un bloque de tiempo
  Future<void> upsertTimeBlock(TimeBlock block) async {
    final supa = client;
    final user = currentUser;
    if (supa == null || user == null) return;

    try {
      final map = block.toSupabaseMap();
      map['user_id'] = user.id;
      map['updated_at'] = DateTime.now().toUtc().toIso8601String();

      await supa.from('time_blocks').upsert(map);
    } catch (e) {
      debugPrint('[SupabaseService] Error al guardar time_block: $e');
    }
  }

  /// Elimina un bloque de tiempo
  Future<void> deleteTimeBlock(String blockId) async {
    final supa = client;
    final user = currentUser;
    if (supa == null || user == null) return;

    try {
      await supa
          .from('time_blocks')
          .delete()
          .eq('id', blockId)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('[SupabaseService] Error al eliminar time_block: $e');
    }
  }

  // ──────────────────────────────────────────────
  // Base de Datos: Tareas ToDo (Backlog)
  // ──────────────────────────────────────────────

  /// Obtiene todas las tareas ToDo del usuario desde Supabase
  Future<List<TodoItem>> fetchTodos() async {
    final supa = client;
    final user = currentUser;
    if (supa == null || user == null) return [];

    try {
      final response = await supa
          .from('todos')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<TodoItem> list = [];
      for (final row in response) {
        list.add(TodoItem.fromSupabaseMap(Map<String, dynamic>.from(row)));
      }
      return list;
    } catch (e) {
      debugPrint('[SupabaseService] Error al obtener todos: $e');
      return [];
    }
  }

  /// Inserta o actualiza una tarea ToDo
  Future<void> upsertTodo(TodoItem todo) async {
    final supa = client;
    final user = currentUser;
    if (supa == null || user == null) return;

    try {
      final map = todo.toSupabaseMap();
      map['user_id'] = user.id;
      map['updated_at'] = DateTime.now().toUtc().toIso8601String();

      await supa.from('todos').upsert(map);
    } catch (e) {
      debugPrint('[SupabaseService] Error al guardar todo: $e');
    }
  }

  /// Elimina una tarea ToDo
  Future<void> deleteTodo(String todoId) async {
    final supa = client;
    final user = currentUser;
    if (supa == null || user == null) return;

    try {
      await supa
          .from('todos')
          .delete()
          .eq('id', todoId)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('[SupabaseService] Error al eliminar todo: $e');
    }
  }
}
