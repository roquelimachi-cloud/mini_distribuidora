import 'package:supabase_flutter/supabase_flutter.dart';

class ProveedoresService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // OBTENER TODOS LOS PROVEEDORES
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerProveedores({
    bool incluirInactivos = true,
  }) async {
    try {
      var query = _supabase
          .from('proveedores')
          .select(
            'id, nombre, documento, telefono, direccion, contacto, activo',
          );

      if (!incluirInactivos) {
        query = query.eq('activo', true);
      }

      final data = await query.order('nombre');

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('ERROR OBTENIENDO PROVEEDORES: $e');
      rethrow;
    }
  }

  // ============================================================
  // CREAR PROVEEDOR
  // ============================================================

  Future<Map<String, dynamic>> crearProveedor({
    required String nombre,
    String? documento,
    String? telefono,
    String? direccion,
    String? contacto,
  }) async {
    try {
      final data = await _supabase
          .from('proveedores')
          .insert({
            'nombre': nombre.trim(),
            'documento': _limpiar(documento),
            'telefono': _limpiar(telefono),
            'direccion': _limpiar(direccion),
            'contacto': _limpiar(contacto),
            'activo': true,
          })
          .select()
          .single();

      print('PROVEEDOR CREADO: $data');

      return Map<String, dynamic>.from(data);
    } catch (e) {
      print('ERROR CREANDO PROVEEDOR: $e');
      rethrow;
    }
  }

  // ============================================================
  // ACTUALIZAR PROVEEDOR
  // ============================================================

  Future<Map<String, dynamic>> actualizarProveedor({
    required String id,
    required String nombre,
    String? documento,
    String? telefono,
    String? direccion,
    String? contacto,
  }) async {
    try {
      final data = await _supabase
          .from('proveedores')
          .update({
            'nombre': nombre.trim(),
            'documento': _limpiar(documento),
            'telefono': _limpiar(telefono),
            'direccion': _limpiar(direccion),
            'contacto': _limpiar(contacto),
          })
          .eq('id', id)
          .select()
          .single();

      print('PROVEEDOR ACTUALIZADO: $data');

      return Map<String, dynamic>.from(data);
    } catch (e) {
      print('ERROR ACTUALIZANDO PROVEEDOR: $e');
      rethrow;
    }
  }

  // ============================================================
  // ACTIVAR / DESACTIVAR
  // ============================================================

  Future<void> cambiarEstadoProveedor({
    required String id,
    required bool activo,
  }) async {
    try {
      await _supabase
          .from('proveedores')
          .update({
            'activo': activo,
          })
          .eq('id', id);

      print(
        'PROVEEDOR $id → ${activo ? 'ACTIVO' : 'INACTIVO'}',
      );
    } catch (e) {
      print('ERROR CAMBIANDO ESTADO: $e');
      rethrow;
    }
  }

  // ============================================================
  // LIMPIAR CAMPOS OPCIONALES
  // ============================================================

  String? _limpiar(String? valor) {
    if (valor == null) {
      return null;
    }

    final texto = valor.trim();

    if (texto.isEmpty) {
      return null;
    }

    return texto;
  }
}