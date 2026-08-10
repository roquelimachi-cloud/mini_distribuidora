import 'package:supabase_flutter/supabase_flutter.dart';

class ComprasService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // OBTENER PROVEEDORES
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerProveedores() async {
    try {
      final data = await _supabase
          .from('proveedores')
          .select(
            'id, nombre, documento, telefono, direccion, contacto, activo',
          )
          .eq('activo', true)
          .order('nombre');

      print('====================================');
      print('PROVEEDORES ENCONTRADOS: ${data.length}');
      print('DATOS PROVEEDORES: $data');
      print('====================================');

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('====================================');
      print('ERROR PROVEEDORES: $e');
      print('====================================');
      rethrow;
    }
  }

  // ============================================================
  // REGISTRAR COMPRA
  // ============================================================

  Future registrarCompra({
    required String proveedorId,
    required String metodoPago,
    required List<Map<String, dynamic>> items,
    double descuento = 0,
    String? observaciones,
  }) async {
    try {
      print('====================================');
      print('REGISTRANDO COMPRA');
      print('PROVEEDOR: $proveedorId');
      print('MÉTODO PAGO: $metodoPago');
      print('ITEMS: $items');
      print('DESCUENTO: $descuento');
      print('OBSERVACIONES: $observaciones');
      print('====================================');

      final resultado = await _supabase.rpc(
        'registrar_compra',
        params: {
          'p_proveedor_id': proveedorId,
          'p_metodo_pago': metodoPago,
          'p_items': items,
          'p_descuento': descuento,
          'p_observaciones': observaciones,
        },
      );

      print('====================================');
      print('COMPRA REGISTRADA CORRECTAMENTE');
      print('RESULTADO: $resultado');
      print('====================================');

      return resultado;
    } catch (e) {
      print('====================================');
      print('ERROR REGISTRANDO COMPRA: $e');
      print('====================================');
      rethrow;
    }
  }

  // ============================================================
  // ANULAR COMPRA
  // ============================================================

  Future<dynamic> anularCompra(String compraId) async {
    try {
      print('====================================');
      print('ANULANDO COMPRA');
      print('COMPRA ID: $compraId');
      print('====================================');

      final resultado = await _supabase.rpc(
        'anular_compra',
        params: {
          'p_compra_id': compraId,
        },
      );

      print('====================================');
      print('COMPRA ANULADA CORRECTAMENTE');
      print('RESULTADO: $resultado');
      print('====================================');

      return resultado;
    } catch (e) {
      print('====================================');
      print('ERROR ANULANDO COMPRA: $e');
      print('====================================');
      rethrow;
    }
  }

  // ============================================================
  // OBTENER HISTORIAL DE COMPRAS
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerCompras() async {
    try {
      final data = await _supabase
          .from('compras')
          .select(
            '''
            id,
            numero_compra,
            proveedor_id,
            metodo_pago,
            descuento,
            total,
            estado,
            observaciones,
            created_at,
            proveedores (
              id,
              nombre,
              documento,
              telefono
            )
            ''',
          )
          .order('created_at', ascending: false);

      print('====================================');
      print('COMPRAS ENCONTRADAS: ${data.length}');
      print('====================================');

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('====================================');
      print('ERROR OBTENIENDO COMPRAS: $e');
      print('====================================');
      rethrow;
    }
  }

  // ============================================================
  // OBTENER DETALLE DE UNA COMPRA
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerDetalleCompra(
    String compraId,
  ) async {
    try {
      final data = await _supabase
          .from('detalle_compras')
          .select(
            '''
            id,
            compra_id,
            producto_id,
            cantidad,
            precio_unitario,
            subtotal,
            productos (
              id,
              codigo,
              nombre,
              marca
            )
            ''',
          )
          .eq('compra_id', compraId);

      print('====================================');
      print('DETALLE DE COMPRA: $compraId');
      print('ITEMS ENCONTRADOS: ${data.length}');
      print('====================================');

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('====================================');
      print('ERROR OBTENIENDO DETALLE: $e');
      print('====================================');
      rethrow;
    }
  }

  // ============================================================
  // OBTENER UNA COMPRA POR ID
  // ============================================================

  Future<Map<String, dynamic>?> obtenerCompraPorId(
    String compraId,
  ) async {
    try {
      final data = await _supabase
          .from('compras')
          .select(
            '''
            id,
            numero_compra,
            proveedor_id,
            metodo_pago,
            descuento,
            total,
            estado,
            observaciones,
            created_at,
            proveedores (
              id,
              nombre,
              documento,
              telefono,
              direccion,
              contacto
            )
            ''',
          )
          .eq('id', compraId)
          .maybeSingle();

      return data;
    } catch (e) {
      print('====================================');
      print('ERROR OBTENIENDO COMPRA: $e');
      print('====================================');
      rethrow;
    }
  }

  // ============================================================
  // ÚLTIMAS COMPRAS
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerUltimasCompras({
    int limite = 5,
  }) async {
    try {
      final data = await _supabase
          .from('compras')
          .select(
            '''
            id,
            numero_compra,
            proveedor_id,
            metodo_pago,
            descuento,
            total,
            estado,
            observaciones,
            created_at,
            proveedores (
              id,
              nombre
            )
            ''',
          )
          .order('created_at', ascending: false)
          .limit(limite);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('====================================');
      print('ERROR OBTENIENDO ÚLTIMAS COMPRAS: $e');
      print('====================================');
      rethrow;
    }
  }
}
