import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/producto.dart';
import '../services/productos_service.dart';
import '../services/compras_service.dart';
import '../services/comprobante_compra_service.dart';

class ComprasPage extends StatefulWidget {
  const ComprasPage({super.key});

  @override
  State<ComprasPage> createState() => _ComprasPageState();
}

class _ComprasPageState extends State<ComprasPage> {
  final ProductosService _productosService =
      ProductosService();

  final ComprasService _comprasService =
      ComprasService();

  final TextEditingController _buscarController =
      TextEditingController();

  final TextEditingController _descuentoController =
      TextEditingController(text: '0');

  final TextEditingController _observacionesController =
      TextEditingController();

  final TextEditingController _buscarCompraController =
      TextEditingController();

  List<Producto> productos = [];
  List<Producto> resultados = [];

  List<Map<String, dynamic>> proveedores = [];

  List<Map<String, dynamic>> compras = [];
  List<Map<String, dynamic>> comprasFiltradas = [];

  Map<String, dynamic>? proveedorSeleccionado;

  final List<Map<String, dynamic>> carrito = [];

  String metodoPago = 'Efectivo';

  bool cargando = true;
  bool guardando = false;
  bool cargandoHistorial = false;

  int vistaActual = 0;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    _descuentoController.dispose();
    _observacionesController.dispose();
    _buscarCompraController.dispose();
    super.dispose();
  }

  // ============================================================
  // CARGAR DATOS
  // ============================================================

  Future<void> cargarDatos() async {
    try {
      final productosData =
          await _productosService.obtenerProductos();

      final proveedoresData =
          await _comprasService.obtenerProveedores();

      if (!mounted) return;

      setState(() {
        productos = productosData;
        resultados = productosData;

        proveedores =
            List<Map<String, dynamic>>.from(
          proveedoresData,
        );

        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      mostrarMensaje(
        'Error cargando datos:\n$e',
        error: true,
      );
    }
  }

  // ============================================================
  // CARGAR HISTORIAL
  // ============================================================

  Future<void> cargarHistorial() async {
    setState(() {
      cargandoHistorial = true;
    });

    try {
      final data =
          await _comprasService.obtenerCompras();

      if (!mounted) return;

      setState(() {
        compras =
            List<Map<String, dynamic>>.from(data);

        comprasFiltradas =
            List<Map<String, dynamic>>.from(data);

        cargandoHistorial = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargandoHistorial = false;
      });

      mostrarMensaje(
        'Error cargando historial:\n$e',
        error: true,
      );
    }
  }

  // ============================================================
  // CAMBIAR VISTA
  // ============================================================

  void cambiarVista(int vista) {
    setState(() {
      vistaActual = vista;
    });

    if (vista == 1 &&
        compras.isEmpty) {
      cargarHistorial();
    }
  }

  // ============================================================
  // BUSCAR PRODUCTO
  // ============================================================

  void buscarProducto(String texto) {
    final busqueda =
        texto.trim().toLowerCase();

    setState(() {
      if (busqueda.isEmpty) {
        resultados = productos;
      } else {
        resultados =
            productos.where((producto) {
          return producto.nombre
                  .toLowerCase()
                  .contains(busqueda) ||
              producto.codigo
                  .toLowerCase()
                  .contains(busqueda) ||
              producto.marca
                  .toLowerCase()
                  .contains(busqueda);
        }).toList();
      }
    });
  }

  // ============================================================
  // BUSCAR COMPRA
  // ============================================================

  void buscarCompra(String texto) {
    final busqueda =
        texto.trim().toLowerCase();

    setState(() {
      if (busqueda.isEmpty) {
        comprasFiltradas =
            List<Map<String, dynamic>>.from(
          compras,
        );

        return;
      }

      comprasFiltradas =
          compras.where((compra) {
        final numero =
            (compra['numero_compra'] ?? '')
                .toString()
                .toLowerCase();

        final proveedor =
            _nombreProveedor(compra)
                .toLowerCase();

        final metodo =
            (compra['metodo_pago'] ?? '')
                .toString()
                .toLowerCase();

        return numero.contains(busqueda) ||
            proveedor.contains(busqueda) ||
            metodo.contains(busqueda);
      }).toList();
    });
  }

  // ============================================================
  // PROVEEDOR
  // ============================================================

  String _nombreProveedor(
    Map<String, dynamic> compra,
  ) {
    final proveedor =
        compra['proveedores'];

    if (proveedor is Map) {
      return proveedor['nombre']
              ?.toString() ??
          'Sin proveedor';
    }

    return 'Sin proveedor';
  }

  // ============================================================
  // FECHA
  // ============================================================

  String _formatearFecha(
    dynamic valor,
  ) {
    if (valor == null) {
      return '-';
    }

    try {
      final fecha =
          DateTime.parse(
        valor.toString(),
      ).toLocal();

      String dos(int numero) =>
          numero.toString().padLeft(
            2,
            '0',
          );

      return '${dos(fecha.day)}/'
          '${dos(fecha.month)}/'
          '${fecha.year} '
          '${dos(fecha.hour)}:'
          '${dos(fecha.minute)}';
    } catch (_) {
      return valor.toString();
    }
  }

  // ============================================================
  // AGREGAR PRODUCTO
  // ============================================================

  void agregarProducto(
    Producto producto,
  ) {
    final indice =
        carrito.indexWhere(
      (item) =>
          item['producto'].id ==
          producto.id,
    );

    if (indice >= 0) {
      final cantidad =
          carrito[indice]['cantidad']
              as int;

      setState(() {
        carrito[indice]['cantidad'] =
            cantidad + 1;
      });
    } else {
      setState(() {
        carrito.add({
          'producto': producto,
          'cantidad': 1,
          'precio':
              producto.precioCompra,
        });
      });
    }
  }

  // ============================================================
  // CANTIDADES
  // ============================================================

  void aumentarCantidad(
    int indice,
  ) {
    final cantidad =
        carrito[indice]['cantidad']
            as int;

    setState(() {
      carrito[indice]['cantidad'] =
          cantidad + 1;
    });
  }

  void disminuirCantidad(
    int indice,
  ) {
    final cantidad =
        carrito[indice]['cantidad']
            as int;

    if (cantidad <= 1) {
      setState(() {
        carrito.removeAt(indice);
      });

      return;
    }

    setState(() {
      carrito[indice]['cantidad'] =
          cantidad - 1;
    });
  }

  // ============================================================
  // PRECIO
  // ============================================================

  void cambiarPrecio(
    int indice,
    String valor,
  ) {
    final precio =
        double.tryParse(valor) ?? 0;

    carrito[indice]['precio'] =
        precio;

    setState(() {});
  }

  // ============================================================
  // TOTALES
  // ============================================================

  double get subtotal {
    double total = 0;

    for (final item in carrito) {
      final cantidad =
          item['cantidad'] as int;

      final precio =
          (item['precio'] as num)
              .toDouble();

      total += cantidad * precio;
    }

    return total;
  }

  double get descuento {
    // Acepta tanto 5.00 como 5,00.
    final texto = _descuentoController.text
        .trim()
        .replaceAll(',', '.');

    return double.tryParse(texto) ?? 0;
  }

  double get total {
    final resultado =
        subtotal - descuento;

    return resultado < 0
        ? 0
        : resultado;
  }

  // ============================================================
  // REGISTRAR COMPRA
  // ============================================================
Future<void> registrarCompra() async {
  if (proveedorSeleccionado == null) {
    mostrarMensaje(
      'Selecciona un proveedor.',
      error: true,
    );
    return;
  }

  if (carrito.isEmpty) {
    mostrarMensaje(
      'Agrega al menos un producto.',
      error: true,
    );
    return;
  }

  if (descuento < 0) {
    mostrarMensaje(
      'El descuento no puede ser negativo.',
      error: true,
    );
    return;
  }

  if (descuento > subtotal) {
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
    final items = carrito.map((item) {
      final Producto producto = item['producto'];

      final int cantidad = item['cantidad'];

      final double precio =
          (item['precio'] as num).toDouble();

      return {
        'producto_id': producto.id,
        'cantidad': cantidad,
        'precio_unitario': precio,
      };
    }).toList();

    // ============================================================
    // DEBUG
    // ============================================================

    print('========================================');
    print('INICIANDO REGISTRO DE COMPRA');
    print('========================================');

    print('PROVEEDOR: ${proveedorSeleccionado!['id']}');
    print('PROVEEDOR NOMBRE: ${proveedorSeleccionado!['nombre']}');
    print('MÉTODO PAGO: $metodoPago');
    print('DESCUENTO: $descuento');
    print('SUBTOTAL: $subtotal');
    print('TOTAL: $total');

    print('ITEMS ENVIADOS A SUPABASE:');

    for (final item in items) {
      print(item);
    }

    print('========================================');

    final resultado = await _comprasService.registrarCompra(
      proveedorId:
          proveedorSeleccionado!['id'].toString(),
      metodoPago: metodoPago,
      items: items,
      descuento: descuento,
      observaciones:
          _observacionesController.text.trim().isEmpty
              ? null
              : _observacionesController.text.trim(),
    );

    print('========================================');
    print('RPC REGISTRAR_COMPRA RESPONDIÓ');
    print('RESULTADO: $resultado');
    print('========================================');

    if (!mounted) return;

    setState(() {
      carrito.clear();
      proveedorSeleccionado = null;
      metodoPago = 'Efectivo';
      _descuentoController.text = '0';
      _observacionesController.clear();
      guardando = false;
    });

    mostrarMensaje(
      'Compra registrada correctamente.',
    );

    await cargarHistorial();
    await cargarDatos();

  } catch (e, stackTrace) {
    print('========================================');
    print('ERROR REGISTRANDO COMPRA DESDE FLUTTER');
    print('========================================');
    print('ERROR: $e');
    print('STACKTRACE: $stackTrace');
    print('========================================');

    if (!mounted) return;

    setState(() {
      guardando = false;
    });

    mostrarMensaje(
      'No se pudo registrar la compra:\n$e',
      error: true,
    );
  }
}
  // ============================================================
  // ANULAR COMPRA
  // ============================================================

  Future<void> anularCompra(Map<String, dynamic> compra) async {
    final compraId = compra['id']?.toString();
    final numero = compra['numero_compra']?.toString() ?? 'Sin número';
    final estado = (compra['estado'] ?? 'activa').toString().toLowerCase();

    if (compraId == null || compraId.isEmpty) {
      mostrarMensaje(
        'No se encontró el ID de la compra.',
        error: true,
      );
      return;
    }

    if (estado == 'anulada') {
      mostrarMensaje(
        'Esta compra ya está anulada.',
        error: true,
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('Anular compra'),
            ],
          ),
          content: Text(
            '¿Seguro que deseas anular la compra $numero?\n\n'
            'La compra no se eliminará. Se marcará como anulada '
            'y el stock será revertido por Supabase.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sí, anular'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    if (!mounted) return;

    setState(() {
      cargandoHistorial = true;
    });

    try {
      await _comprasService.anularCompra(compraId);

      if (!mounted) return;

      mostrarMensaje(
        'Compra $numero anulada correctamente.',
      );

      await cargarHistorial();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargandoHistorial = false;
      });

      mostrarMensaje(
        'No se pudo anular la compra:\n$e',
        error: true,
      );
    }
  }

  // ============================================================
  // IMPRIMIR / COMPROBANTE MR
  // ============================================================

  Future<void> imprimirCompra(
    Map<String, dynamic> compra,
  ) async {
    final compraId = compra['id']?.toString();

    if (compraId == null || compraId.isEmpty) {
      mostrarMensaje(
        'No se encontró el ID de la compra.',
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
          await _comprasService.obtenerDetalleCompra(compraId);

      if (!mounted) return;

      Navigator.of(context).pop();

      final bytes =
          await ComprobanteCompraService.generarComprobante(
        compra: compra,
        detalle: detalle,
      );

      if (!mounted) return;

      await Printing.layoutPdf(
        name:
            '${compra['numero_compra'] ?? 'comprobante'}_MR.pdf',
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

  // ============================================================
  // DETALLE DE COMPRA
  // ============================================================

  Future<void> mostrarDetalleCompra(
    Map<String, dynamic> compra,
  ) async {
    final compraId =
        compra['id']?.toString();

    if (compraId == null) {
      mostrarMensaje(
        'No se encontró el ID de la compra.',
        error: true,
      );

      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child:
              CircularProgressIndicator(),
        );
      },
    );

    try {
      final detalle =
          await _comprasService
              .obtenerDetalleCompra(
        compraId,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      await showDialog(
        context: context,
        builder: (context) {
          return _dialogoDetalleCompra(
            compra,
            detalle,
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop();

      mostrarMensaje(
        'Error obteniendo detalle:\n$e',
        error: true,
      );
    }
  }

  // ============================================================
  // DIÁLOGO DETALLE
  // ============================================================

  Widget _dialogoDetalleCompra(
    Map<String, dynamic> compra,
    List<Map<String, dynamic>> detalle,
  ) {
    final numero =
        compra['numero_compra']
            ?.toString() ??
        'Sin número';

    final proveedor =
        _nombreProveedor(compra);

    final metodo =
        compra['metodo_pago']
            ?.toString() ??
        '-';

    final totalCompra =
        (compra['total'] as num?)
                ?.toDouble() ??
            0;

    final descuentoCompra =
        (compra['descuento'] as num?)
                ?.toDouble() ??
            0;

    final observaciones =
        compra['observaciones']
                ?.toString() ??
            '';

    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.receipt_long,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              numero,
              overflow:
                  TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _datoDetalle(
                'Proveedor',
                proveedor,
              ),
              _datoDetalle(
                'Fecha',
                _formatearFecha(
                  compra['created_at'],
                ),
              ),
              _datoDetalle(
                'Método de pago',
                metodo,
              ),

              _datoDetalle(
                'Estado',
                (compra['estado'] ?? 'activa').toString().toUpperCase(),
              ),

              const SizedBox(height: 15),

              const Text(
                'Productos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              if (detalle.isEmpty)
                const Text(
                  'No hay productos registrados.',
                ),

              ...detalle.map(
                (item) {
                  return _detalleProducto(
                    item,
                  );
                },
              ),

              const Divider(
                height: 30,
              ),

              _filaTotal(
                'Descuento',
                descuentoCompra,
              ),

              const SizedBox(height: 8),

              _filaTotal(
                'TOTAL',
                totalCompra,
                destacado: true,
              ),

              if (observaciones
                  .trim()
                  .isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Observaciones',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(observaciones),
              ],
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            imprimirCompra(compra);
          },
          icon: const Icon(
            Icons.print_outlined,
          ),
          label: const Text(
            'Imprimir',
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context)
                .pop();
          },
          child:
              const Text('Cerrar'),
        ),
      ],
    );
  }

  // ============================================================
  // DATO DETALLE
  // ============================================================

  Widget _datoDetalle(
    String titulo,
    String valor,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 6,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$titulo:',
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(valor),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETALLE PRODUCTO
  // ============================================================

  Widget _detalleProducto(
    Map<String, dynamic> item,
  ) {
    final producto =
        item['productos'];

    String nombre =
        'Producto';

    String codigo = '';

    String marca = '';

    if (producto is Map) {
      nombre =
          producto['nombre']
                  ?.toString() ??
              'Producto';

      codigo =
          producto['codigo']
                  ?.toString() ??
              '';

      marca =
          producto['marca']
                  ?.toString() ??
              '';
    }

    final cantidad =
        (item['cantidad'] as num?)
                ?.toDouble() ??
            0;

    final precio =
        (item['precio_unitario']
                    as num?)
                ?.toDouble() ??
            0;

    final subtotalItem =
        (item['subtotal'] as num?)
                ?.toDouble() ??
            (cantidad * precio);

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              nombre,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            if (codigo.isNotEmpty ||
                marca.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(
                  top: 3,
                ),
                child: Text(
                  [
                    if (codigo.isNotEmpty)
                      codigo,
                    if (marca.isNotEmpty)
                      marca,
                  ].join(' • '),
                  style:
                      TextStyle(
                    color: Colors
                        .grey
                        .shade700,
                    fontSize: 13,
                  ),
                ),
              ),

            const SizedBox(
              height: 8,
            ),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cantidad: '
                    '${cantidad.toStringAsFixed(0)}',
                  ),
                ),
                Expanded(
                  child: Text(
                    'Costo: '
                    'S/ ${precio.toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: Text(
                    'Subtotal: '
                    'S/ ${subtotalItem.toStringAsFixed(2)}',
                    textAlign:
                        TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MENSAJE
  // ============================================================

  void mostrarMensaje(
    String mensaje, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(mensaje),
        backgroundColor:
            error
                ? Colors.red
                : Colors.green,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compras',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          if (vistaActual == 1)
            IconButton(
              tooltip:
                  'Actualizar historial',
              onPressed:
                  cargarHistorial,
              icon: const Icon(
                Icons.refresh,
              ),
            ),
        ],
      ),

      body: cargando
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Column(
              children: [
                _selectorVistas(),

                Expanded(
                  child:
                      vistaActual == 0
                          ? _vistaNuevaCompra()
                          : _vistaHistorial(),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // SELECTOR DE VISTAS
  // ============================================================

  Widget _selectorVistas() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      child: SizedBox(
        width: double.infinity,
        child:
            SegmentedButton<int>(
          segments: const [
            ButtonSegment<int>(
              value: 0,
              icon: Icon(
                Icons.add_shopping_cart,
              ),
              label:
                  Text('Nueva compra'),
            ),
            ButtonSegment<int>(
              value: 1,
              icon: Icon(
                Icons.history,
              ),
              label:
                  Text('Historial'),
            ),
          ],
          selected: {
            vistaActual,
          },
          onSelectionChanged:
              (selection) {
            cambiarVista(
              selection.first,
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // VISTA NUEVA COMPRA
  // ============================================================

  Widget _vistaNuevaCompra() {
    return LayoutBuilder(
      builder:
          (context, constraints) {
        if (constraints.maxWidth >=
            900) {
          return _vistaEscritorio();
        }

        return _vistaMovil();
      },
    );
  }

  // ============================================================
  // ESCRITORIO
  // ============================================================

  Widget _vistaEscritorio() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Scrollbar(
            thumbVisibility:
                true,
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.only(
                left: 20,
                right: 10,
                top: 20,
                bottom: 20,
              ),
              child:
                  _productosPanel(
                padding:
                    EdgeInsets.zero,
              ),
            ),
          ),
        ),

        VerticalDivider(
          width: 1,
          color:
              Colors.grey.shade300,
        ),

        Expanded(
          flex: 2,
          child: Scrollbar(
            thumbVisibility:
                true,
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.only(
                left: 10,
                right: 20,
                top: 20,
                bottom: 20,
              ),
              child:
                  _compraPanel(
                padding:
                    EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CELULAR
  // ============================================================

  Widget _vistaMovil() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          _productosPanel(
            padding:
                EdgeInsets.zero,
          ),

          const SizedBox(
            height: 24,
          ),

          _compraPanel(
            padding:
                EdgeInsets.zero,
          ),

          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PANEL PRODUCTOS
  // ============================================================

  Widget _productosPanel({
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(20),
  }) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Productos',
            style: TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          TextField(
            controller:
                _buscarController,
            onChanged:
                buscarProducto,
            decoration:
                InputDecoration(
              hintText:
                  'Buscar producto, código o marca...',
              prefixIcon:
                  const Icon(
                Icons.search,
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          if (resultados.isEmpty)
            const Padding(
              padding:
                  EdgeInsets.all(20),
              child: Text(
                'No se encontraron productos.',
              ),
            ),

          ...resultados.map(
            (producto) =>
                _productoCard(
              producto,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TARJETA PRODUCTO
  // ============================================================

  Widget _productoCard(
    Producto producto,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        leading:
            const CircleAvatar(
          child: Icon(
            Icons.inventory_2,
          ),
        ),
        title: Text(
          producto.nombre,
          maxLines: 2,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${producto.marca} • '
          '${producto.codigo}\n'
          'Stock: '
          '${producto.stockActual.toStringAsFixed(0)}'
          ' • Costo actual: '
          'S/ ${producto.precioCompra.toStringAsFixed(2)}',
          maxLines: 2,
          overflow:
              TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing:
            FilledButton(
          onPressed:
              () => agregarProducto(
            producto,
          ),
          child:
              const Text('Agregar'),
        ),
      ),
    );
  }

  // ============================================================
  // PANEL COMPRA
  // ============================================================

  Widget _compraPanel({
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(20),
  }) {
    return Container(
      padding: padding,
      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalle de compra',
            style: TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          // PROVEEDOR

          DropdownButtonFormField<
              Map<String, dynamic>>(
            value:
                proveedorSeleccionado,
            isExpanded: true,
            decoration:
                const InputDecoration(
              labelText:
                  'Proveedor',
              hintText:
                  'Selecciona un proveedor',
              prefixIcon:
                  Icon(
                Icons.business,
              ),
              border:
                  OutlineInputBorder(),
            ),
            items: proveedores
                .map(
                  (proveedor) {
                    return DropdownMenuItem<
                        Map<String,
                            dynamic>>(
                      value:
                          proveedor,
                      child: Text(
                        proveedor[
                                    'nombre']
                                ?.toString() ??
                            'Sin nombre',
                        overflow:
                            TextOverflow
                                .ellipsis,
                      ),
                    );
                  },
                )
                .toList(),
            onChanged:
                proveedores.isEmpty
                    ? null
                    : (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setState(() {
                          proveedorSeleccionado =
                              value;
                        });
                      },
          ),

          if (proveedores.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 8,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.red,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  const Expanded(
                    child: Text(
                      'No se encontraron proveedores.',
                    ),
                  ),
                  TextButton(
                    onPressed:
                        cargarDatos,
                    child:
                        const Text(
                      'Reintentar',
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(
            height: 20,
          ),

          // CARRITO VACÍO

          if (carrito.isEmpty)
            const Padding(
              padding:
                  EdgeInsets.symmetric(
                vertical: 30,
              ),
              child: Center(
                child: Text(
                  'No hay productos agregados.',
                ),
              ),
            ),

          // CARRITO

          ...carrito
              .asMap()
              .entries
              .map(
                (entry) =>
                    _carritoItem(
                  entry.key,
                  entry.value,
                ),
              ),

          if (carrito.isNotEmpty) ...[
            const Divider(
              height: 30,
            ),

            _filaTotal(
              'Subtotal',
              subtotal,
            ),

            const SizedBox(
              height: 12,
            ),

            TextField(
              controller:
                  _descuentoController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Descuento',
                hintText: 'Ej.: 5.00',
                prefixText: 'S/ ',
                helperText:
                    'Ingresa el descuento en soles. Ejemplo: S/ 5.00',
                prefixIcon: const Icon(
                  Icons.local_offer_outlined,
                ),
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            _filaTotal(
              'Descuento aplicado',
              descuento,
            ),

            const SizedBox(height: 10),

            _filaTotal(
              'Total',
              total,
              destacado: true,
            ),

            const SizedBox(
              height: 20,
            ),

            DropdownButtonFormField<
                String>(
              value: metodoPago,
              isExpanded: true,
              decoration:
                  const InputDecoration(
                labelText:
                    'Método de pago',
                border:
                    OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Efectivo',
                  child: Text(
                    'Efectivo',
                  ),
                ),
                DropdownMenuItem(
                  value: 'Yape/Plin',
                  child: Text(
                    'Yape / Plin',
                  ),
                ),
                DropdownMenuItem(
                  value:
                      'Transferencia',
                  child: Text(
                    'Transferencia',
                  ),
                ),
                DropdownMenuItem(
                  value: 'Tarjeta',
                  child: Text(
                    'Tarjeta',
                  ),
                ),
                DropdownMenuItem(
                  value: 'Credito',
                  child: Text(
                    'Crédito',
                  ),
                ),
              ],
              onChanged:
                  (value) {
                if (value ==
                    null) {
                  return;
                }

                setState(() {
                  metodoPago =
                      value;
                });
              },
            ),

            const SizedBox(
              height: 20,
            ),

            TextField(
              controller:
                  _observacionesController,
              maxLines: 3,
              decoration:
                  const InputDecoration(
                labelText:
                    'Observaciones',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              width:
                  double.infinity,
              height: 52,
              child:
                  FilledButton.icon(
                onPressed:
                    guardando
                        ? null
                        : registrarCompra,
                icon: guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check,
                      ),
                label: Text(
                  guardando
                      ? 'Registrando...'
                      : 'Registrar compra',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

    // ============================================================
  // HISTORIAL
  // ============================================================

  Widget _vistaHistorial() {
    final cantidadCompras = comprasFiltradas.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            8,
          ),
          
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Historial de compras',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$cantidadCompras '
                      '${cantidadCompras == 1 ? 'compra' : 'compras'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  IconButton(
                    tooltip: 'Actualizar historial',
                    onPressed: cargandoHistorial
                        ? null
                        : cargarHistorial,
                    icon: const Icon(
                      Icons.refresh,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _buscarCompraController,
                onChanged: buscarCompra,
                decoration: InputDecoration(
                  hintText:
                      'Buscar compra, proveedor o método de pago...',
                  prefixIcon: const Icon(
                    Icons.search,
                  ),
                  suffixIcon:
                      _buscarCompraController.text.isNotEmpty
                          ? IconButton(
                              tooltip: 'Limpiar búsqueda',
                              onPressed: () {
                                _buscarCompraController.clear();
                                buscarCompra('');
                              },
                              icon: const Icon(
                                Icons.clear,
                              ),
                            )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: cargandoHistorial
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : comprasFiltradas.isEmpty
                  ? _historialVacio()
                  : RefreshIndicator(
                      onRefresh: cargarHistorial,
                      child: ListView.builder(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          20,
                        ),
                        itemCount: comprasFiltradas.length,
                        itemBuilder: (context, index) {
                          final compra =
                              comprasFiltradas[index];

                          return _tarjetaCompra(
                            compra,
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
  // ============================================================
  // HISTORIAL VACÍO
  // ============================================================

  Widget _historialVacio() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 70,
              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(
              height: 15,
            ),

            const Text(
              'No hay compras registradas',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Las compras registradas aparecerán aquí.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            FilledButton.icon(
              onPressed:
                  cargarHistorial,
              icon: const Icon(
                Icons.refresh,
              ),
              label:
                  const Text(
                'Actualizar',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TARJETA COMPRA
  // ============================================================

  Widget _tarjetaCompra(
    Map<String, dynamic> compra,
  ) {
    final numero =
        compra['numero_compra']
                ?.toString() ??
            'Sin número';

    final proveedor =
        _nombreProveedor(compra);

    final metodo =
        compra['metodo_pago']
                ?.toString() ??
            '-';

    final totalCompra =
        (compra['total'] as num?)
                ?.toDouble() ??
            0;

    final descuentoCompra =
        (compra['descuento'] as num?)
                ?.toDouble() ??
            0;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        onTap: () =>
            mostrarDetalleCompra(
          compra,
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets
                            .all(10),
                    decoration:
                        BoxDecoration(
                      color: Theme.of(
                        context,
                      )
                          .colorScheme
                          .primaryContainer,
                      borderRadius:
                          BorderRadius
                              .circular(
                        10,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons
                          .receipt_long,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

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
                            fontSize: 17,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          proveedor,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              TextStyle(
                            color: Colors
                                .grey
                                .shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Text(
                    'S/ ${totalCompra.toStringAsFixed(2)}',
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 14,
              ),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chipInfo(
                    Icons
                        .calendar_today,
                    _formatearFecha(
                      compra[
                          'created_at'],
                    ),
                  ),
                  _chipInfo(
                    Icons
                        .payments_outlined,
                    metodo,
                  ),
                  if (descuentoCompra >
                      0)
                    _chipInfo(
                      Icons
                          .local_offer_outlined,
                      'Desc. S/ ${descuentoCompra.toStringAsFixed(2)}',
                    ),

                  _chipEstadoCompra(
                    (compra['estado'] ?? 'activa').toString(),
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              const Divider(
                height: 1,
              ),

              const SizedBox(
                height: 10,
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => mostrarDetalleCompra(compra),
                    icon: const Icon(
                      Icons.visibility_outlined,
                    ),
                    label: const Text('Ver detalle'),
                  ),

                  const SizedBox(width: 4),

                  TextButton.icon(
                    onPressed: () => imprimirCompra(compra),
                    icon: const Icon(
                      Icons.print_outlined,
                    ),
                    label: const Text('Imprimir'),
                  ),

                  const SizedBox(width: 8),

                  if ((compra['estado'] ?? 'activa')
                          .toString()
                          .toLowerCase() !=
                      'anulada')
                    TextButton.icon(
                      onPressed: () => anularCompra(compra),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      icon: const Icon(
                        Icons.cancel_outlined,
                      ),
                      label: const Text('Anular'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CHIP ESTADO
  // ============================================================

  Widget _chipEstadoCompra(String estado) {
    final anulada = estado.toLowerCase() == 'anulada';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: anulada
            ? Colors.red.withOpacity(0.10)
            : Colors.green.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: anulada
              ? Colors.red.withOpacity(0.30)
              : Colors.green.withOpacity(0.30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            anulada
                ? Icons.cancel_outlined
                : Icons.check_circle_outline,
            size: 15,
            color: anulada ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 5),
          Text(
            anulada ? 'ANULADA' : 'ACTIVA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: anulada ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHIP
  // ============================================================

  Widget _chipInfo(
    IconData icon,
    String texto,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            texto,
            style:
                const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARRITO
  // ============================================================

  Widget _carritoItem(
    int indice,
    Map<String, dynamic> item,
  ) {
    final Producto producto =
        item['producto'];

    final int cantidad =
        item['cantidad'];

    final double precio =
        (item['precio'] as num)
            .toDouble();

    final double totalItem =
        precio * cantidad;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Expanded(
                  child: Text(
                    producto.nombre,
                    maxLines: 2,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  tooltip:
                      'Eliminar producto',
                  onPressed: () {
                    setState(() {
                      carrito
                          .removeAt(
                        indice,
                      );
                    });
                  },
                  icon:
                      const Icon(
                    Icons
                        .delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            TextField(
              keyboardType:
                  const TextInputType
                      .numberWithOptions(
                decimal: true,
              ),
              controller:
                  TextEditingController(
                text: precio
                    .toStringAsFixed(
                  2,
                ),
              ),
              onChanged:
                  (value) {
                cambiarPrecio(
                  indice,
                  value,
                );
              },
              decoration:
                  const InputDecoration(
                labelText:
                    'Costo unitario',
                prefixText:
                    'S/ ',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Row(
              children: [
                IconButton(
                  tooltip:
                      'Disminuir cantidad',
                  onPressed: () =>
                      disminuirCantidad(
                    indice,
                  ),
                  icon:
                      const Icon(
                    Icons
                        .remove_circle_outline,
                  ),
                ),

                Text(
                  cantidad.toString(),
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 17,
                  ),
                ),

                IconButton(
                  tooltip:
                      'Aumentar cantidad',
                  onPressed: () =>
                      aumentarCantidad(
                    indice,
                  ),
                  icon:
                      const Icon(
                    Icons
                        .add_circle_outline,
                  ),
                ),

                const Spacer(),

                Flexible(
                  child: Text(
                    'S/ ${totalItem.toStringAsFixed(2)}',
                    textAlign:
                        TextAlign.end,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILA TOTAL
  // ============================================================

  Widget _filaTotal(
    String titulo,
    double valor, {
    bool destacado = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize:
                destacado
                    ? 20
                    : 16,
            fontWeight:
                destacado
                    ? FontWeight.bold
                    : FontWeight.normal,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Flexible(
          child: Text(
            'S/ ${valor.toStringAsFixed(2)}',
            textAlign:
                TextAlign.end,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              fontSize:
                  destacado
                      ? 22
                      : 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}