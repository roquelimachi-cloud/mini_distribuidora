class Producto {
  final String id;
  final String codigo;
  final String nombre;
  final String marca;
  final String presentacion;
  final String contenido;
  final int unidadesPorEmpaque;
  final double precioCompra;
  final double precioVenta;
  final double margenPorcentaje;
  final double stockActual;

  const Producto({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.marca,
    required this.presentacion,
    required this.contenido,
    required this.unidadesPorEmpaque,
    required this.precioCompra,
    required this.precioVenta,
    required this.margenPorcentaje,
    required this.stockActual,
  });

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id']?.toString() ?? '',
      codigo: map['codigo']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      marca: map['marca']?.toString() ?? '',
      presentacion: map['presentacion']?.toString() ?? '',
      contenido: map['contenido']?.toString() ?? '',
      unidadesPorEmpaque:
          int.tryParse(
            map['unidades_por_empaque']?.toString() ?? '0',
          ) ??
          0,
      precioCompra:
          double.tryParse(
            map['precio_compra']?.toString() ?? '0',
          ) ??
          0,
      precioVenta:
          double.tryParse(
            map['precio_venta']?.toString() ?? '0',
          ) ??
          0,
      margenPorcentaje:
          double.tryParse(
            map['margen_porcentaje']?.toString() ?? '0',
          ) ??
          0,
      stockActual:
          double.tryParse(
            map['stock_actual']?.toString() ?? '0',
          ) ??
          0,
    );
  }
}