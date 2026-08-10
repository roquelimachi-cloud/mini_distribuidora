import 'package:supabase_flutter/supabase_flutter.dart';

class VentasService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ============================================================
  // REGISTRAR VENTA
  // ============================================================

  Future<dynamic> registrarVenta({
    String? clienteId,
    required String metodoPago,
    required List<Map<String, dynamic>> items,
    double descuento = 0,
    String? observaciones,
  }) async {
    return await _supabase.rpc(
      'registrar_venta',
      params: {
        'p_cliente_id': clienteId,
        'p_metodo_pago': metodoPago,
        'p_items': items,
        'p_descuento': descuento,
        'p_observaciones': observaciones,
      },
    );
  }

  // ============================================================
  // HISTORIAL DE VENTAS
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerVentas() async {
    final data = await _supabase
        .from('ventas')
        .select(
          '''
          id,
          numero_venta,
          cliente_id,
          fecha,
          subtotal,
          descuento,
          total,
          metodo_pago,
          estado,
          observaciones
          ''',
        )
        .order('fecha', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ============================================================
  // DETALLE DE UNA VENTA
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerDetalleVenta(
    String ventaId,
  ) async {
    final data = await _supabase
        .from('detalle_ventas')
        .select(
          '''
          id,
          venta_id,
          producto_id,
          cantidad,
          precio_unitario,
          costo_unitario,
          subtotal,
          productos (
            id,
            codigo,
            nombre,
            marca
          )
          ''',
        )
        .eq('venta_id', ventaId);

    return List<Map<String, dynamic>>.from(data);
  }

  // ============================================================
  // OBTENER UNA VENTA POR ID
  // ============================================================

  Future<Map<String, dynamic>?> obtenerVentaPorId(
    String ventaId,
  ) async {
    return await _supabase
        .from('ventas')
        .select(
          '''
          id,
          numero_venta,
          cliente_id,
          fecha,
          subtotal,
          descuento,
          total,
          metodo_pago,
          estado,
          observaciones
          ''',
        )
        .eq('id', ventaId)
        .maybeSingle();
  }
}
