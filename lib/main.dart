import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'pages/ventas_page.dart';
import 'pages/compras_page.dart';
import 'pages/productos_page.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const MiniDistribuidoraApp());
}

class MiniDistribuidoraApp extends StatelessWidget {
  const MiniDistribuidoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mini Distribuidora',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool cargando = true;
  String? error;

  double ventasHoy = 0;
  double ventasMes = 0;
  double utilidadMes = 0;
  double inventarioValorizado = 0;

  int cantidadProductos = 0;
  int productosStockBajo = 0;

  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> ultimasVentas = [];

  @override
  void initState() {
    super.initState();
    cargarDashboard();
  }

  Future<void> cargarDashboard() async {
    String paso = 'iniciando';

    try {
      final supabase = Supabase.instance.client;

      final ahora = DateTime.now();

      final inicioDia = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
      );

      final inicioMes = DateTime(
        ahora.year,
        ahora.month,
        1,
      );

      final inicioMesIso = inicioMes.toUtc().toIso8601String();

      final inicioDiaIso = inicioDia.toUtc().toIso8601String();

      // ------------------------------------------------------------
      // CONSULTAS PRINCIPALES EN PARALELO
      // ------------------------------------------------------------

      paso = 'consultando datos principales';

      final resultados = await Future.wait([
        // Ventas del mes:
        // solamente necesitamos los campos necesarios.
        supabase
            .from('ventas')
            .select(
              'id, numero_venta, fecha, total, metodo_pago, estado',
            )
            .eq('estado', 'completada')
            .gte('fecha', inicioMesIso)
            .order(
              'fecha',
              ascending: false,
            ),

        // Productos:
        // necesarios para inventario y stock bajo.
        supabase
            .from('productos')
            .select(
              'id, codigo, nombre, marca, '
              'precio_compra, precio_venta, stock_actual',
            )
            .order('nombre'),
      ]);

      final ventasMesData =
          List<Map<String, dynamic>>.from(
        resultados[0] as List,
      );

      final productosData =
          List<Map<String, dynamic>>.from(
        resultados[1] as List,
      );

      // ------------------------------------------------------------
      // CALCULAR VENTAS
      // ------------------------------------------------------------

      paso = 'calculando ventas';

      double totalHoy = 0;
      double totalMes = 0;

      for (final venta in ventasMesData) {
        final fechaTexto =
            venta['fecha']?.toString();

        if (fechaTexto == null) {
          continue;
        }

        final fecha =
            DateTime.tryParse(fechaTexto);

        if (fecha == null) {
          continue;
        }

        final total =
            double.tryParse(
              venta['total']?.toString() ?? '0',
            ) ??
            0;

        totalMes += total;

        if (!fecha.isBefore(inicioDia)) {
          totalHoy += total;
        }
      }

      // ------------------------------------------------------------
      // ÚLTIMAS 5 VENTAS
      // ------------------------------------------------------------

      paso = 'consultando últimas ventas';

      final ultimasVentasData = await supabase
          .from('ventas')
          .select(
            'id, numero_venta, fecha, '
            'total, metodo_pago, estado',
          )
          .order(
            'fecha',
            ascending: false,
          )
          .limit(5);

      final ultimas =
          List<Map<String, dynamic>>.from(
        ultimasVentasData,
      );

      // ------------------------------------------------------------
      // DETALLES DEL MES
      // ------------------------------------------------------------

   paso = 'consultando detalle de ventas';

final ventaIds = ventasMesData
    .map((venta) => venta['id'])
    .where((id) => id != null)
    .toList();

List<Map<String, dynamic>> detallesData = [];

if (ventaIds.isNotEmpty) {
  final detallesResponse = await supabase
      .from('detalle_ventas')
      .select(
        'venta_id, producto_id, cantidad, '
        'precio_unitario, costo_unitario, subtotal',
      )
      .inFilter('venta_id', ventaIds);

  detallesData = List<Map<String, dynamic>>.from(
    detallesResponse,
  );
}
      // ------------------------------------------------------------
      // UTILIDAD
      // ------------------------------------------------------------

      paso = 'calculando utilidad';

      double utilidad = 0;

      for (final detalle in detallesData) {
        final cantidad =
            double.tryParse(
              detalle['cantidad']?.toString() ?? '0',
            ) ??
            0;

        final precio =
            double.tryParse(
              detalle['precio_unitario']?.toString() ?? '0',
            ) ??
            0;

        final costo =
            double.tryParse(
              detalle['costo_unitario']?.toString() ?? '0',
            ) ??
            0;

        utilidad +=
            (precio - costo) * cantidad;
      }

      // ------------------------------------------------------------
      // INVENTARIO
      // ------------------------------------------------------------

      paso = 'calculando inventario';

      double valorInventario = 0;
      int stockBajo = 0;

      for (final producto in productosData) {
        final costo =
            double.tryParse(
              producto['precio_compra']?.toString() ?? '0',
            ) ??
            0;

        final stock =
            double.tryParse(
              producto['stock_actual']?.toString() ?? '0',
            ) ??
            0;

        valorInventario += costo * stock;

        if (stock <= 5) {
          stockBajo++;
        }
      }

      // ------------------------------------------------------------
      // ACTUALIZAR INTERFAZ
      // ------------------------------------------------------------

      if (!mounted) return;

      setState(() {
        ventasHoy = totalHoy;
        ventasMes = totalMes;
        utilidadMes = utilidad;
        inventarioValorizado = valorInventario;

        cantidadProductos =
            productosData.length;

        productosStockBajo = stockBajo;

        productos = productosData;

        ultimasVentas = ultimas;

        cargando = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error =
            'PASO QUE FALLÓ:\n$paso\n\n'
            'ERROR:\n$e';

        cargando = false;
      });
    }
  }

  Future<void> abrirCompras() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ComprasPage(),
      ),
    );

    if (!mounted) return;

    await cargarDashboard();
  }

  Future<void> abrirVentas() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const VentasPage(),
      ),
    );

    if (!mounted) return;

    await cargarDashboard();
  }

  Future<void> abrirProductos() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ProductosPage(),
      ),
    );

    if (!mounted) return;

    await cargarDashboard();
  }

  Future<void> actualizarDashboard() async {
    setState(() {
      cargando = true;
      error = null;
    });

    await cargarDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mini Distribuidora',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Nueva compra',
            onPressed: abrirCompras,
            icon: const Icon(
              Icons.shopping_cart,
            ),
          ),
          IconButton(
            tooltip: 'Nueva venta',
            onPressed: abrirVentas,
            icon: const Icon(
              Icons.point_of_sale,
            ),
          ),
          IconButton(
            tooltip: 'Productos',
            onPressed: abrirProductos,
            icon: const Icon(
              Icons.inventory_2,
            ),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: actualizarDashboard,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            'ERROR AL CARGAR DASHBOARD:\n\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: cargarDashboard,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Resumen de tu mini distribuidora',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 24),

            _buildIndicadores(),

            const SizedBox(height: 30),

            _buildInventario(),

            const SizedBox(height: 30),

            _buildUltimasVentas(),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicadores() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;

        int columnas;

        if (ancho >= 1100) {
          columnas = 4;
        } else if (ancho >= 700) {
          columnas = 2;
        } else {
          columnas = 1;
        }

        final tarjetas = [
          _buildTarjeta(
            'Ventas hoy',
            'S/ ${ventasHoy.toStringAsFixed(2)}',
            Icons.point_of_sale,
          ),
          _buildTarjeta(
            'Ventas del mes',
            'S/ ${ventasMes.toStringAsFixed(2)}',
            Icons.trending_up,
          ),
          _buildTarjeta(
            'Productos',
            cantidadProductos.toString(),
            Icons.inventory_2,
          ),
          _buildTarjeta(
            'Stock bajo',
            productosStockBajo.toString(),
            Icons.warning_amber,
          ),
          _buildTarjeta(
            'Utilidad',
            'S/ ${utilidadMes.toStringAsFixed(2)}',
            Icons.monetization_on,
          ),
          _buildTarjeta(
            'Inventario',
            'S/ ${inventarioValorizado.toStringAsFixed(2)}',
            Icons.warehouse,
          ),
        ];

        return GridView.count(
          crossAxisCount: columnas,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio:
              columnas == 1 ? 3.2 : 2.7,
          children: tarjetas,
        );
      },
    );
  }

  Widget _buildTarjeta(
    String titulo,
    String valor,
    IconData icono,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Icon(
                icono,
                color: Colors.blue,
                size: 28,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    valor,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventario() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Inventario',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 14),

        ...productos.map(
          (producto) {
            final nombre =
                producto['nombre']
                        ?.toString() ??
                    '';

            final marca =
                producto['marca']
                        ?.toString() ??
                    '';

            final stock =
                double.tryParse(
                      producto['stock_actual']
                              ?.toString() ??
                          '0',
                    ) ??
                    0;

            final precioVenta =
                double.tryParse(
                      producto['precio_venta']
                              ?.toString() ??
                          '0',
                    ) ??
                    0;

            final bajo = stock <= 5;

            return Card(
              margin:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder:
                      (context, constraints) {
                    final esMovil =
                        constraints.maxWidth <
                            600;

                    final productoInfo =
                        Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration:
                                BoxDecoration(
                              color: bajo
                                  ? Colors.red
                                      .withValues(
                                      alpha: 0.10,
                                    )
                                  : Colors.green
                                      .withValues(
                                      alpha: 0.10,
                                    ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                            child: Icon(
                              bajo
                                  ? Icons
                                      .warning_amber
                                  : Icons
                                      .inventory_2,
                              color: bajo
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  nombre,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 3,
                                ),

                                Text(
                                  marca,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style: TextStyle(
                                    color: Colors
                                        .grey
                                        .shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );

                    final valores =
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Stock: '
                          '${stock.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color: bajo
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          'S/ '
                          '${precioVenta.toStringAsFixed(2)}',
                        ),
                      ],
                    );

                    if (esMovil) {
                      return Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Row(
                            children: [
                              productoInfo,

                              const SizedBox(
                                width: 10,
                              ),

                              valores,
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        productoInfo,

                        const SizedBox(
                          width: 16,
                        ),

                        valores,
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUltimasVentas() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimas ventas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 14),

        if (ultimasVentas.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Todavía no hay ventas registradas.',
              ),
            ),
          ),

        ...ultimasVentas.map(
          (venta) {
            final numero =
                venta['numero_venta']
                        ?.toString() ??
                    '';

            final metodo =
                venta['metodo_pago']
                        ?.toString() ??
                    '';

            final estado =
                venta['estado']
                        ?.toString() ??
                    '';

            final total =
                double.tryParse(
                      venta['total']
                              ?.toString() ??
                          '0',
                    ) ??
                    0;

            return Card(
              margin:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              child: ListTile(
                leading:
                    const CircleAvatar(
                  child: Icon(
                    Icons.receipt_long,
                  ),
                ),
                title: Text(
                  numero,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '$metodo • $estado',
                ),
                trailing: Text(
                  'S/ '
                  '${total.toStringAsFixed(2)}',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}