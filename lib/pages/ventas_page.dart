import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/producto.dart';
import '../services/productos_service.dart';
import '../services/ventas_service.dart';
import '../services/comprobante_venta_service.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  final ProductosService _productosService = ProductosService();

  final VentasService _ventasService = VentasService();

  final TextEditingController _buscarController =
      TextEditingController();

  final TextEditingController _descuentoController =
      TextEditingController(text: '0');

  final TextEditingController _buscarVentaController =
      TextEditingController();

  List<Producto> productos = [];
  List<Producto> resultados = [];

  final List<Map<String, dynamic>> carrito = [];

  List<Map<String, dynamic>> ventas = [];
  List<Map<String, dynamic>> ventasFiltradas = [];

  String metodoPago = 'Efectivo';

  bool cargando = true;
  bool guardando = false;
  bool cargandoHistorial = false;

  int vistaActual = 0;

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    _descuentoController.dispose();
    _buscarVentaController.dispose();
    super.dispose();
  }

  Future<void> cargarProductos() async {
    try {
      final data = await _productosService.obtenerProductos();

      if (!mounted) return;

      setState(() {
        productos = data;
        resultados = data;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      mostrarMensaje(
        'Error cargando productos: $e',
        error: true,
      );
    }
  }

  void buscarProducto(String texto) {
    final busqueda = texto.trim().toLowerCase();

    setState(() {
      if (busqueda.isEmpty) {
        resultados = productos;
      } else {
        resultados = productos.where((producto) {
          return producto.nombre.toLowerCase().contains(busqueda) ||
              producto.codigo.toLowerCase().contains(busqueda) ||
              producto.marca.toLowerCase().contains(busqueda);
        }).toList();
      }
    });
  }

  void agregarProducto(Producto producto) {
    if (producto.stockActual <= 0) {
      mostrarMensaje(
        'No hay stock disponible de ${producto.nombre}.',
        error: true,
      );
      return;
    }

    final indice = carrito.indexWhere(
      (item) => item['producto'].id == producto.id,
    );

    if (indice >= 0) {
      final cantidad = carrito[indice]['cantidad'] as int;

      if (cantidad + 1 > producto.stockActual) {
        mostrarMensaje(
          'No puedes superar el stock disponible.',
          error: true,
        );
        return;
      }

      setState(() {
        carrito[indice]['cantidad'] = cantidad + 1;
      });
    } else {
      setState(() {
        carrito.add({
          'producto': producto,
          'cantidad': 1,
        });
      });
    }
  }

  void aumentarCantidad(int indice) {
    final item = carrito[indice];
    final Producto producto = item['producto'];
    final cantidad = item['cantidad'] as int;

    if (cantidad + 1 > producto.stockActual) {
      mostrarMensaje(
        'Stock máximo disponible: '
        '${producto.stockActual.toStringAsFixed(0)}',
        error: true,
      );
      return;
    }

    setState(() {
      item['cantidad'] = cantidad + 1;
    });
  }

  void disminuirCantidad(int indice) {
    final cantidad = carrito[indice]['cantidad'] as int;

    if (cantidad <= 1) {
      setState(() {
        carrito.removeAt(indice);
      });
      return;
    }

    setState(() {
      carrito[indice]['cantidad'] = cantidad - 1;
    });
  }

  void eliminarProducto(int indice) {
    setState(() {
      carrito.removeAt(indice);
    });
  }

  double get subtotal {
    double total = 0;

    for (final item in carrito) {
      final Producto producto = item['producto'];
      final int cantidad = item['cantidad'];

      total += producto.precioVenta * cantidad;
    }

    return total;
  }

  double get descuento {
    final texto = _descuentoController.text
        .trim()
        .replaceAll(',', '.');

    final valor = double.tryParse(texto) ?? 0;

    if (valor < 0) return 0;
    if (valor > subtotal) return subtotal;

    return valor;
  }

  double get total => subtotal - descuento;

  Future<void> registrarVenta() async {
    if (carrito.isEmpty) {
      mostrarMensaje(
        'Agrega al menos un producto.',
        error: true,
      );
      return;
    }

    final descuentoIngresado = double.tryParse(
      _descuentoController.text.trim().replaceAll(',', '.'),
    );

    if (descuentoIngresado == null || descuentoIngresado < 0) {
      mostrarMensaje(
        'Ingresa un descuento válido.',
        error: true,
      );
      return;
    }

    if (descuentoIngresado > subtotal) {
      mostrarMensaje(
        'El descuento no puede ser mayor al subtotal.',
        error: true,
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final detalles = carrito.map((item) {
        final Producto producto = item['producto'];
        final int cantidad = item['cantidad'];

        return {
          'producto_id': producto.id,
          'cantidad': cantidad,
          'precio_unitario': producto.precioVenta,
          'costo_unitario': producto.precioCompra,
        };
      }).toList();

      await _ventasService.registrarVenta(
        clienteId: null,
        metodoPago: metodoPago,
        items: detalles,
        descuento: descuento,
        observaciones: 'Venta registrada desde Flutter',
      );

      if (!mounted) return;

      setState(() {
        carrito.clear();
        _descuentoController.text = '0';
        guardando = false;
      });

      mostrarMensaje(
        'Venta registrada correctamente.',
      );

      await cargarProductos();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        guardando = false;
      });

      mostrarMensaje(
        'No se pudo registrar la venta:\n$e',
        error: true,
      );
    }
  }

  // ============================================================
  // HISTORIAL DE VENTAS
  // ============================================================

  Future<void> cargarHistorial() async {
    setState(() {
      cargandoHistorial = true;
    });

    try {
      final data = await _ventasService.obtenerVentas();

      if (!mounted) return;

      setState(() {
        ventas = List<Map<String, dynamic>>.from(data);
        ventasFiltradas =
            List<Map<String, dynamic>>.from(data);
        cargandoHistorial = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargandoHistorial = false;
      });

      mostrarMensaje(
        'No se pudo cargar el historial de ventas.',
        error: true,
      );
    }
  }

  void buscarVenta(String texto) {
    final busqueda = texto.trim().toLowerCase();

    setState(() {
      if (busqueda.isEmpty) {
        ventasFiltradas =
            List<Map<String, dynamic>>.from(ventas);
        return;
      }

      ventasFiltradas = ventas.where((venta) {
        final numero =
            venta['numero_venta']?.toString().toLowerCase() ?? '';
        final metodo =
            venta['metodo_pago']?.toString().toLowerCase() ?? '';
        final estado =
            venta['estado']?.toString().toLowerCase() ?? '';

        return numero.contains(busqueda) ||
            metodo.contains(busqueda) ||
            estado.contains(busqueda);
      }).toList();
    });
  }

  void cambiarVista(int vista) {
    setState(() {
      vistaActual = vista;
    });

    if (vista == 1 && ventas.isEmpty) {
      cargarHistorial();
    }
  }

  // ============================================================
  // IMPRIMIR / COMPROBANTE MR
  // ============================================================

  Future<void> imprimirVenta(
    Map<String, dynamic> venta,
  ) async {
    final ventaId = venta['id']?.toString();

    if (ventaId == null || ventaId.isEmpty) {
      mostrarMensaje(
        'No se encontró el ID de la venta.',
        error: true,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final detalle =
          await _ventasService.obtenerDetalleVenta(ventaId);

      if (!mounted) return;

      Navigator.of(context).pop();

      final bytes =
          await ComprobanteVentaService.generarComprobante(
        venta: venta,
        detalle: detalle,
      );

      if (!mounted) return;

      await Printing.layoutPdf(
        name:
            '${venta['numero_venta'] ?? 'comprobante'}_MR.pdf',
        onLayout: (_) async => bytes,
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop();

      mostrarMensaje(
        'No se pudo generar el comprobante:\n$e',
        error: true,
      );
    }
  }

  Future<void> mostrarDetalleVenta(
    Map<String, dynamic> venta,
  ) async {
    final ventaId = venta['id']?.toString();

    if (ventaId == null || ventaId.isEmpty) {
      mostrarMensaje(
        'No se encontró el ID de la venta.',
        error: true,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final detalle =
          await _ventasService.obtenerDetalleVenta(ventaId);

      if (!mounted) return;

      Navigator.of(context).pop();

      await showDialog(
        context: context,
        builder: (dialogContext) {
          final numero =
              venta['numero_venta']?.toString() ?? 'Sin número';
          final subtotal =
              double.tryParse(
                    venta['subtotal']?.toString() ?? '0',
                  ) ??
                  0;
          final descuento =
              double.tryParse(
                    venta['descuento']?.toString() ?? '0',
                  ) ??
                  0;
          final total =
              double.tryParse(
                    venta['total']?.toString() ?? '0',
                  ) ??
                  0;
          final estado =
              venta['estado']?.toString() ?? 'completada';

          return AlertDialog(
            title: Text('Detalle $numero'),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Método de pago: '
                      '${venta['metodo_pago'] ?? '—'}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estado: ${estado.toUpperCase()}',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Productos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (detalle.isEmpty)
                      const Text(
                        'No hay productos registrados.',
                      )
                    else
                      ...detalle.map((item) {
                        final cantidad =
                            double.tryParse(
                                  item['cantidad']?.toString() ??
                                      '0',
                                ) ??
                                0;
                        final precio =
                            double.tryParse(
                                  item['precio_unitario']
                                          ?.toString() ??
                                      '0',
                                ) ??
                                0;
                        final subtotalItem =
                            double.tryParse(
                                  item['subtotal']?.toString() ??
                                      '0',
                                ) ??
                                cantidad * precio;

                        final producto =
                            item['productos'];

                        final nombre =
                            producto is Map<String, dynamic>
                                ? producto['nombre']?.toString() ??
                                    'Producto'
                                : 'Producto';

                        final codigo =
                            producto is Map<String, dynamic>
                                ? producto['codigo']?.toString() ?? ''
                                : '';

                        return Card(
                          margin:
                              const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(nombre),
                            subtitle: Text(
                              '$codigo • '
                              '${cantidad.toStringAsFixed(0)} x '
                              'S/ ${precio.toStringAsFixed(2)}',
                            ),
                            trailing: Text(
                              'S/ ${subtotalItem.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                    const Divider(height: 24),
                    _filaTotal(
                      'Subtotal',
                      subtotal,
                    ),
                    const SizedBox(height: 6),
                    _filaTotal(
                      'Descuento',
                      descuento,
                    ),
                    const SizedBox(height: 6),
                    _filaTotal(
                      'Total',
                      total,
                      destacado: true,
                    ),
                    if ((venta['observaciones']
                            ?.toString()
                            .trim()
                            .isNotEmpty ??
                        false)) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Observaciones',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        venta['observaciones']
                                ?.toString() ??
                            '',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  imprimirVenta(venta);
                },
                icon: const Icon(Icons.print_outlined),
                label: const Text('Imprimir'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop();

      mostrarMensaje(
        'No se pudo consultar el detalle de la venta.',
        error: true,
      );
    }
  }

  String _formatearFecha(dynamic valor) {
    final fecha = DateTime.tryParse(
      valor?.toString() ?? '',
    );

    if (fecha == null) return 'Sin fecha';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
  }

  Widget _historialPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Historial de ventas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!cargandoHistorial)
                Text(
                  '${ventasFiltradas.length} ventas',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: cargarHistorial,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _buscarVentaController,
            onChanged: buscarVenta,
            decoration: InputDecoration(
              hintText:
                  'Buscar venta, método de pago o estado...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Limpiar',
                onPressed: () {
                  _buscarVentaController.clear();
                  buscarVenta('');
                },
                icon: const Icon(Icons.clear),
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 15),
          if (cargandoHistorial)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (ventasFiltradas.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 56,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No hay ventas registradas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Las ventas registradas aparecerán aquí.',
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: ventasFiltradas.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final venta =
                      ventasFiltradas[index];

                  final numero =
                      venta['numero_venta']
                              ?.toString() ??
                          'Sin número';

                  final total =
                      double.tryParse(
                            venta['total']
                                    ?.toString() ??
                                '0',
                          ) ??
                          0;

                  final descuento =
                      double.tryParse(
                            venta['descuento']
                                    ?.toString() ??
                                '0',
                          ) ??
                          0;

                  final estado =
                      venta['estado']
                              ?.toString()
                              .toLowerCase() ??
                          'completada';

                  final activa =
                      estado == 'completada';

                  return Card(
                    margin: EdgeInsets.zero,
                    elevation: 1,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    Colors.blue.shade50,
                                child: Icon(
                                  Icons
                                      .receipt_long_outlined,
                                  color:
                                      Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      numero,
                                      style:
                                          const TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      'Cliente no registrado',
                                      style: TextStyle(
                                        color: Colors
                                            .grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'S/ ${total.toStringAsFixed(2)}',
                                style:
                                    const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                avatar: const Icon(
                                  Icons
                                      .calendar_today_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  _formatearFecha(
                                    venta['fecha'],
                                  ),
                                ),
                              ),
                              Chip(
                                avatar: const Icon(
                                  Icons
                                      .payments_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  venta['metodo_pago']
                                          ?.toString() ??
                                      '—',
                                ),
                              ),
                              if (descuento > 0)
                                Chip(
                                  avatar: const Icon(
                                    Icons
                                        .local_offer_outlined,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'Desc. S/ '
                                    '${descuento.toStringAsFixed(2)}',
                                  ),
                                ),
                              Chip(
                                avatar: Icon(
                                  activa
                                      ? Icons
                                          .check_circle_outline
                                      : Icons
                                          .cancel_outlined,
                                  size: 16,
                                  color: activa
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                label: Text(
                                  activa
                                      ? 'ACTIVA'
                                      : 'ANULADA',
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Align(
                            alignment:
                                Alignment.centerRight,
                            child: Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      imprimirVenta(
                                    venta,
                                  ),
                                  icon: const Icon(
                                    Icons.print_outlined,
                                  ),
                                  label: const Text(
                                    'Imprimir',
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      mostrarDetalleVenta(
                                    venta,
                                  ),
                                  icon: const Icon(
                                    Icons
                                        .visibility_outlined,
                                  ),
                                  label: const Text(
                                    'Ver detalle',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void mostrarMensaje(
    String mensaje, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ventas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    8,
                  ),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 0,
                        icon: Icon(
                          Icons.point_of_sale_outlined,
                        ),
                        label: Text('Nueva venta'),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        icon: Icon(
                          Icons.history,
                        ),
                        label: Text('Historial'),
                      ),
                    ],
                    selected: {vistaActual},
                    onSelectionChanged: (value) {
                      cambiarVista(value.first);
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: vistaActual == 0
                      ? LayoutBuilder(
                          builder:
                              (context, constraints) {
                            if (constraints.maxWidth >=
                                900) {
                              return _vistaEscritorio();
                            }

                            return _vistaMovil();
                          },
                        )
                      : _historialPanel(),
                ),
              ],
            ),
    );
  }

  Widget _vistaEscritorio() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _productosPanel(),
        ),
        Expanded(
          flex: 2,
          child: _carritoPanel(),
        ),
      ],
    );
  }

  Widget _vistaMovil() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _productosPanel(),
          const SizedBox(height: 20),
          _carritoPanel(),
        ],
      ),
    );
  }

  Widget _productosPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Productos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: _buscarController,
            onChanged: buscarProducto,
            decoration: InputDecoration(
              hintText: 'Buscar producto, código o marca...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 15),

          if (resultados.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No se encontraron productos.',
              ),
            ),

          ...resultados.map(
            (producto) => _productoCard(producto),
          ),
        ],
      ),
    );
  }

  Widget _productoCard(Producto producto) {
    final sinStock = producto.stockActual <= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final esMovil = constraints.maxWidth < 520;

            final informacion = Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: sinStock
                        ? Colors.red.shade50
                        : Colors.blue.shade50,
                    child: Icon(
                      Icons.local_drink,
                      color: sinStock ? Colors.red : Colors.blue,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          '${producto.marca} • ${producto.codigo}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'Stock: '
                          '${producto.stockActual.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: sinStock
                                ? Colors.red
                                : Colors.green.shade700,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          'Precio: '
                          'S/ ${producto.precioVenta.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            final boton = SizedBox(
              height: 44,
              child: FilledButton.icon(
                onPressed: sinStock
                    ? null
                    : () => agregarProducto(producto),
                icon: const Icon(
                  Icons.add_shopping_cart,
                ),
                label: const Text('Agregar'),
              ),
            );

            if (esMovil) {
              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  informacion,
                  const SizedBox(height: 12),
                  boton,
                ],
              );
            }

            return Row(
              children: [
                informacion,
                const SizedBox(width: 16),
                boton,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _carritoPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          left: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalle de venta',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          if (carrito.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 30,
              ),
              child: Center(
                child: Text(
                  'No hay productos agregados.',
                ),
              ),
            ),

          ...carrito.asMap().entries.map(
            (entry) {
              return _carritoItem(
                entry.key,
                entry.value,
              );
            },
          ),

          if (carrito.isNotEmpty) ...[
            const Divider(height: 30),

            _filaTotal(
              'Subtotal',
              subtotal,
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _descuentoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Descuento',
                hintText: 'Ej. 5.00',
                prefixText: 'S/ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                helperText:
                    'Descuento aplicado a la venta',
                suffixIcon: IconButton(
                  tooltip: 'Limpiar descuento',
                  onPressed: () {
                    _descuentoController.text = '0';
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (descuento > 0)
              _filaTotal(
                'Descuento',
                descuento,
              ),

            if (descuento > 0)
              const SizedBox(height: 8),

            _filaTotal(
              'Total',
              total,
              destacado: true,
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: metodoPago,
              decoration: const InputDecoration(
                labelText: 'Método de pago',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Efectivo',
                  child: Text('Efectivo'),
                ),
                DropdownMenuItem(
                  value: 'Yape/Plin',
                  child: Text('Yape / Plin'),
                ),
                DropdownMenuItem(
                  value: 'Transferencia',
                  child: Text('Transferencia'),
                ),
                DropdownMenuItem(
                  value: 'Tarjeta',
                  child: Text('Tarjeta'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  metodoPago = value;
                });
              },
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed:
                    guardando ? null : registrarVenta,
                icon: guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check,
                      ),
                label: Text(
                  guardando
                      ? 'Registrando...'
                      : 'Registrar venta',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _carritoItem(
    int indice,
    Map<String, dynamic> item,
  ) {
    final Producto producto = item['producto'];
    final int cantidad = item['cantidad'];

    final totalItem =
        producto.precioVenta * cantidad;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final esMovil = constraints.maxWidth < 520;

            final encabezado = Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Precio unitario: '
                        'S/ ${producto.precioVenta.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                IconButton(
                  tooltip: 'Eliminar',
                  onPressed: () {
                    eliminarProducto(indice);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            );

            final controlesCantidad = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filledTonal(
                  tooltip: 'Disminuir',
                  onPressed: () {
                    disminuirCantidad(indice);
                  },
                  icon: const Icon(
                    Icons.remove,
                  ),
                ),

                const SizedBox(width: 12),

                Container(
                  constraints: const BoxConstraints(
                    minWidth: 42,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    cantidad.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                IconButton.filledTonal(
                  tooltip: 'Aumentar',
                  onPressed: () {
                    aumentarCantidad(indice);
                  },
                  icon: const Icon(
                    Icons.add,
                  ),
                ),
              ],
            );

            final totalWidget = Text(
              'S/ ${totalItem.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            );

            if (esMovil) {
              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  encabezado,

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cantidad',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      controlesCantidad,
                    ],
                  ),

                  const Divider(height: 20),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      totalWidget,
                    ],
                  ),
                ],
              );
            }

            return Column(
              children: [
                encabezado,

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    controlesCantidad,
                    totalWidget,
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filaTotal(
    String titulo,
    double valor, {
    bool destacado = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: destacado ? 20 : 16,
            fontWeight: destacado
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),

        Text(
          'S/ ${valor.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: destacado ? 22 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}