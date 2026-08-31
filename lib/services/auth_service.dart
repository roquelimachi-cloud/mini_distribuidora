import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> iniciarSesion({
    required String usuario,
    required String password,
  }) async {
    final nombreUsuario = usuario.trim().toLowerCase();

    if (nombreUsuario.isEmpty) {
      throw Exception('Ingrese su usuario.');
    }

    if (password.isEmpty) {
      throw Exception('Ingrese su contraseña.');
    }

    try {
      // ============================================================
      // 1. BUSCAR EL USUARIO mroque
      // ============================================================

      final datos = await _supabase
          .from('usuarios')
          .select(
            'id, usuario, nombre, email, perfil_id, activo',
          )
          .eq('usuario', nombreUsuario)
          .maybeSingle();

      if (datos == null) {
        throw Exception(
          'No existe el usuario "$nombreUsuario" en la tabla usuarios.',
        );
      }

      if (datos['activo'] != true) {
        throw Exception(
          'El usuario "$nombreUsuario" está desactivado.',
        );
      }

      final email = datos['email']?.toString().trim();

      if (email == null || email.isEmpty) {
        throw Exception(
          'El usuario "$nombreUsuario" no tiene correo configurado.',
        );
      }

      // ============================================================
      // 2. AUTENTICAR CON SUPABASE AUTH
      // ============================================================

      try {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } on AuthException catch (e) {
        throw Exception(
          'SUPABASE AUTH: ${e.message} '
          '(status: ${e.statusCode ?? "sin código"})',
        );
      }

      // ============================================================
      // 3. OBTENER PERFIL
      // ============================================================

      final perfil = await _supabase
          .from('perfiles')
          .select(
            'id, nombre, descripcion, activo',
          )
          .eq(
            'id',
            datos['perfil_id'],
          )
          .maybeSingle();

      return {
        'id': datos['id'],
        'usuario': datos['usuario'],
        'nombre': datos['nombre'],
        'email': datos['email'],
        'perfil_id': datos['perfil_id'],
        'perfil': perfil,
      };
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Error durante el inicio de sesión: $e',
      );
    }
  }

  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }

  Session? get sesionActual {
    return _supabase.auth.currentSession;
  }

  bool get estaAutenticado {
    return _supabase.auth.currentSession != null;
  }
}