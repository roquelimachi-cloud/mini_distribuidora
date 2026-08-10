import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/producto.dart';

class ProductosService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  Future<List<Producto>> obtenerProductos() async {
    final data = await _supabase
        .from('productos')
        .select(
          'id, codigo, nombre, marca, presentacion, '
          'contenido, unidades_por_empaque, precio_compra, '
          'precio_venta, margen_porcentaje, stock_actual',
        )
        .order('nombre');

    return (data as List)
        .map(
          (item) => Producto.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<void> crearProducto({
    required String nombre,
    String? marca,
    String? presentacion,
    String? contenido,
    String unidadBase = 'unidad',
    int unidadesPorEmpaque = 1,
    required double precioCompra,
    required double precioVenta,
    double? precioMayorista,
    double stockInicial = 0,
    double stockMinimo = 0,
  }) async {
    final margen = precioCompra > 0
        ? ((precioVenta - precioCompra) / precioCompra) * 100
        : 0;

    final datos = <String, dynamic>{
      'nombre': nombre,
      'marca': marca,
      'presentacion': presentacion,
      'contenido': contenido,
      'unidad_base': unidadBase,
      'unidades_por_empaque': unidadesPorEmpaque,
      'precio_compra': precioCompra,
      'precio_venta': precioVenta,
      'precio_mayorista': precioMayorista,
      'stock_actual': stockInicial,
      'stock_minimo': stockMinimo,
      'margen_porcentaje': margen,
      'activo': true,
    };

    await _supabase
        .from('productos')
        .insert(datos);
  }

  Future<void> actualizarProducto({
    required String id,
    required String nombre,
    String? marca,
    String? presentacion,
    String? contenido,
    int unidadesPorEmpaque = 1,
    required double precioCompra,
    required double precioVenta,
    double? precioMayorista,
    double stockMinimo = 0,
  }) async {
    final margen = precioCompra > 0
        ? ((precioVenta - precioCompra) / precioCompra) * 100
        : 0;

    await _supabase
        .from('productos')
        .update({
          'nombre': nombre,
          'marca': marca,
          'presentacion': presentacion,
          'contenido': contenido,
          'unidades_por_empaque': unidadesPorEmpaque,
          'precio_compra': precioCompra,
          'precio_venta': precioVenta,
          'precio_mayorista': precioMayorista,
          'stock_minimo': stockMinimo,
          'margen_porcentaje': margen,
        })
        .eq('id', id);
  }

  Future<void> eliminarProducto(String id) async {
    await _supabase
        .from('productos')
        .delete()
        .eq('id', id);
  }
}