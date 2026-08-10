import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../services/productos_service.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final ProductosService _service = ProductosService();
  final TextEditingController _buscar = TextEditingController();

  List<Producto> _productos = [];
  bool _cargando = true;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _buscar.addListener(_filtrar);
    _cargar();
  }

  @override
  void dispose() {
    _buscar.removeListener(_filtrar);
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);

    try {
      final data = await _service.obtenerProductos();

      if (!mounted) return;

      setState(() {
        _productos = data;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _cargando = false);
      _mensaje('No se pudieron cargar los productos.\n$e', error: true);
    }
  }

  List<Producto> get _resultados {
    final texto = _buscar.text.trim().toLowerCase();

    if (texto.isEmpty) return _productos;

    return _productos.where((p) {
      return p.codigo.toLowerCase().contains(texto) ||
          p.nombre.toLowerCase().contains(texto) ||
          p.marca.toLowerCase().contains(texto) ||
          p.presentacion.toLowerCase().contains(texto);
    }).toList();
  }

  void _filtrar() {
    setState(() {});
  }

  void _mensaje(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? Colors.red.shade700 : null,
        content: Text(texto),
      ),
    );
  }

  Future<void> _nuevoProducto() async {
    final datos = await showDialog<_ProductoDatos>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ProductoDialog(),
    );

    if (datos == null || !mounted) return;

    setState(() => _procesando = true);

    try {
      await _service.crearProducto(
        nombre: datos.nombre,
        marca: datos.marca,
        presentacion: datos.presentacion,
        contenido: datos.contenido,
        unidadBase: datos.unidadBase,
        unidadesPorEmpaque: datos.unidadesPorEmpaque,
        precioCompra: datos.precioCompra,
        precioVenta: datos.precioVenta,
        precioMayorista: datos.precioMayorista,
        stockInicial: datos.stockInicial,
        stockMinimo: datos.stockMinimo,
      );

      await _cargar();

      if (mounted) {
        _mensaje('Producto creado correctamente. El código fue generado automáticamente.');
      }
    } catch (e) {
      if (mounted) {
        _mensaje('No se pudo guardar el producto.\n$e', error: true);
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _editarProducto(Producto producto) async {
    final datos = await showDialog<_ProductoDatos>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProductoDialog(producto: producto),
    );

    if (datos == null || !mounted) return;

    setState(() => _procesando = true);

    try {
      await _service.actualizarProducto(
        id: producto.id,
        nombre: datos.nombre,
        marca: datos.marca,
        presentacion: datos.presentacion,
        contenido: datos.contenido,
        unidadesPorEmpaque: datos.unidadesPorEmpaque,
        precioCompra: datos.precioCompra,
        precioVenta: datos.precioVenta,
        precioMayorista: datos.precioMayorista,
        stockMinimo: datos.stockMinimo,
      );

      await _cargar();

      if (mounted) _mensaje('Producto actualizado correctamente.');
    } catch (e) {
      if (mounted) {
        _mensaje('No se pudo actualizar el producto.\n$e', error: true);
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _eliminarProducto(Producto producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Deseas eliminar "${producto.nombre}" (${producto.codigo})?\n\n'
          'Si este producto ya tiene compras, ventas o movimientos '
          'relacionados, la base de datos puede impedir la eliminación '
          'para proteger el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _procesando = true);

    try {
      await _service.eliminarProducto(producto.id);
      await _cargar();

      if (mounted) _mensaje('Producto eliminado correctamente.');
    } catch (e) {
      if (mounted) {
        _mensaje(
          'No se puede eliminar este producto porque tiene información relacionada '
          'con compras, ventas o inventario.\n\n'
          'El historial debe conservarse.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Productos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _procesando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Catálogo de productos',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _procesando ? null : _nuevoProducto,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo producto'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _buscar,
              decoration: InputDecoration(
                hintText: 'Buscar por código, nombre, marca o presentación...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscar.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _buscar.clear,
                        icon: const Icon(Icons.clear),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_resultados.length} productos',
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _resultados.isEmpty
                      ? const Center(
                          child: Text('No hay productos para mostrar.'),
                        )
                      : ancho >= 900
                          ? _tabla()
                          : _lista(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabla() {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              const Color(0xFFEAF1FA),
            ),
            columns: const [
              DataColumn(label: Text('Código')),
              DataColumn(label: Text('Producto')),
              DataColumn(label: Text('Marca')),
              DataColumn(label: Text('Presentación')),
              DataColumn(label: Text('Empaque')),
              DataColumn(label: Text('Compra')),
              DataColumn(label: Text('Venta')),
              DataColumn(label: Text('Margen')),
              DataColumn(label: Text('Stock')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: _resultados.map((p) {
              final bajo = p.stockActual <= 0;

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      p.codigo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(Text(p.nombre)),
                  DataCell(Text(p.marca.isEmpty ? '-' : p.marca)),
                  DataCell(
                    Text(
                      p.presentacion.isEmpty ? '-' : p.presentacion,
                    ),
                  ),
                  DataCell(Text('${p.unidadesPorEmpaque} unidades')),
                  DataCell(
                    Text('S/ ${p.precioCompra.toStringAsFixed(2)}'),
                  ),
                  DataCell(
                    Text('S/ ${p.precioVenta.toStringAsFixed(2)}'),
                  ),
                  DataCell(
                    Text('${p.margenPorcentaje.toStringAsFixed(2)} %'),
                  ),
                  DataCell(
                    Text(
                      p.stockActual.toStringAsFixed(0),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: bajo
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: _procesando
                              ? null
                              : () => _editarProducto(p),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Eliminar',
                          color: Colors.red.shade700,
                          onPressed: _procesando
                              ? null
                              : () => _eliminarProducto(p),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _lista() {
    return ListView.separated(
      itemCount: _resultados.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final p = _resultados[index];

        return Card(
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEAF1FA),
              child: Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF1F4E79),
              ),
            ),
            title: Text(
              p.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${p.codigo} • ${p.marca} • Stock: ${p.stockActual.toStringAsFixed(0)}',
            ),
            trailing: Wrap(
              children: [
                IconButton(
                  tooltip: 'Editar',
                  onPressed: _procesando ? null : () => _editarProducto(p),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  color: Colors.red.shade700,
                  onPressed:
                      _procesando ? null : () => _eliminarProducto(p),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductoDialog extends StatefulWidget {
  final Producto? producto;

  const _ProductoDialog({
    this.producto,
  });

  @override
  State<_ProductoDialog> createState() => _ProductoDialogState();
}

class _ProductoDialogState extends State<_ProductoDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombre;
  late final TextEditingController _marca;
  late final TextEditingController _presentacion;
  late final TextEditingController _contenido;
  late final TextEditingController _unidades;
  late final TextEditingController _compra;
  late final TextEditingController _venta;
  late final TextEditingController _mayorista;
  late final TextEditingController _stockInicial;
  late final TextEditingController _stockMinimo;

  String _unidadBase = 'unidad';

  bool get _edicion => widget.producto != null;

  @override
  void initState() {
    super.initState();

    final p = widget.producto;

    _nombre = TextEditingController(text: p?.nombre ?? '');
    _marca = TextEditingController(text: p?.marca ?? '');
    _presentacion = TextEditingController(text: p?.presentacion ?? '');
    _contenido = TextEditingController(text: p?.contenido ?? '');
    _unidades = TextEditingController(
      text: p?.unidadesPorEmpaque.toString() ?? '1',
    );
    _compra = TextEditingController(
      text: p?.precioCompra.toStringAsFixed(2) ?? '',
    );
    _venta = TextEditingController(
      text: p?.precioVenta.toStringAsFixed(2) ?? '',
    );
    _mayorista = TextEditingController();
    _stockInicial = TextEditingController(
      text: p?.stockActual.toStringAsFixed(0) ?? '0',
    );
    _stockMinimo = TextEditingController(text: '0');

    _compra.addListener(_actualizar);
    _venta.addListener(_actualizar);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _marca.dispose();
    _presentacion.dispose();
    _contenido.dispose();
    _unidades.dispose();
    _compra.dispose();
    _venta.dispose();
    _mayorista.dispose();
    _stockInicial.dispose();
    _stockMinimo.dispose();
    super.dispose();
  }

  void _actualizar() {
    if (mounted) setState(() {});
  }

  double get _margen {
    final compra = double.tryParse(_compra.text.replaceAll(',', '.')) ?? 0;
    final venta = double.tryParse(_venta.text.replaceAll(',', '.')) ?? 0;

    if (compra <= 0) return 0;

    return ((venta - compra) / compra) * 100;
  }

  double _numero(String value) {
    return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
  }

  String? _obligatorio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio';
    }
    return null;
  }

  String? _numeroValido(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese un valor';
    }

    final n = _numero(value);

    if (n < 0) return 'No puede ser negativo';

    return null;
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      _ProductoDatos(
        nombre: _nombre.text.trim(),
        marca: _marca.text.trim(),
        presentacion: _presentacion.text.trim(),
        contenido: _contenido.text.trim(),
        unidadBase: _unidadBase,
        unidadesPorEmpaque: int.tryParse(_unidades.text.trim()) ?? 1,
        precioCompra: _numero(_compra.text),
        precioVenta: _numero(_venta.text),
        precioMayorista: _mayorista.text.trim().isEmpty
            ? null
            : _numero(_mayorista.text),
        stockInicial: _numero(_stockInicial.text),
        stockMinimo: _numero(_stockMinimo.text),
      ),
    );
  }

  InputDecoration _decoration(
    String label, {
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: Color(0xFF1F4E79),
          ),
          const SizedBox(width: 10),
          Text(_edicion ? 'Editar producto' : 'Nuevo producto'),
        ],
      ),
      content: SizedBox(
        width: ancho > 850 ? 800 : ancho * .88,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _seccion('Información del producto'),

                if (_edicion)
                  TextFormField(
                    initialValue: widget.producto!.codigo,
                    readOnly: true,
                    decoration: _decoration(
                      'Código',
                      icon: Icons.qr_code,
                    ).copyWith(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      suffixIcon: const Icon(Icons.lock_outline),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF1F4E79),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'El código se generará automáticamente al guardar.',
                            style: TextStyle(
                              color: Color(0xFF1F4E79),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                TextFormField(
                  controller: _nombre,
                  decoration: _decoration(
                    'Nombre *',
                    hint: 'Ej. Cerveza Cristal 630 ml',
                    icon: Icons.inventory_2_outlined,
                  ),
                  validator: _obligatorio,
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _marca,
                        decoration: _decoration(
                          'Marca',
                          hint: 'Ej. Cristal',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _presentacion,
                        decoration: _decoration(
                          'Presentación',
                          hint: 'Ej. Botella',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _contenido,
                        decoration: _decoration(
                          'Contenido',
                          hint: 'Ej. 630 ml',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _unidadBase,
                        decoration: _decoration('Unidad base'),
                        items: const [
                          DropdownMenuItem(
                            value: 'unidad',
                            child: Text('Unidad'),
                          ),
                          DropdownMenuItem(
                            value: 'caja',
                            child: Text('Caja'),
                          ),
                          DropdownMenuItem(
                            value: 'paquete',
                            child: Text('Paquete'),
                          ),
                          DropdownMenuItem(
                            value: 'kg',
                            child: Text('Kg'),
                          ),
                          DropdownMenuItem(
                            value: 'litro',
                            child: Text('Litro'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _unidadBase = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unidades,
                        keyboardType: TextInputType.number,
                        decoration: _decoration(
                          'Unidades por empaque',
                          hint: 'Ej. 12',
                        ),
                        validator: (value) {
                          final n = int.tryParse(value ?? '');
                          if (n == null || n <= 0) {
                            return 'Debe ser mayor a 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                _seccion('Precios'),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _compra,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration(
                          'Precio de compra *',
                          hint: '0.00',
                        ),
                        validator: _numeroValido,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _venta,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration(
                          'Precio de venta *',
                          hint: '0.00',
                        ),
                        validator: _numeroValido,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _mayorista,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration(
                          'Precio mayorista',
                          hint: 'Opcional',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Color(0xFF1F4E79),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Margen calculado:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_margen.toStringAsFixed(2)} %',
                        style: const TextStyle(
                          color: Color(0xFF1F4E79),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _seccion('Inventario inicial'),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockInicial,
                        enabled: !_edicion,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration(
                          'Stock inicial',
                          hint: '0',
                          icon: Icons.inventory_outlined,
                        ),
                        validator: _numeroValido,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockMinimo,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration(
                          'Stock mínimo',
                          hint: 'Ej. 12',
                        ),
                        validator: _numeroValido,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _guardar,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar producto'),
        ),
      ],
    );
  }

  Widget _seccion(String texto) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: Text(
        texto,
        style: const TextStyle(
          color: Color(0xFF1F4E79),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ProductoDatos {
  final String nombre;
  final String marca;
  final String presentacion;
  final String contenido;
  final String unidadBase;
  final int unidadesPorEmpaque;
  final double precioCompra;
  final double precioVenta;
  final double? precioMayorista;
  final double stockInicial;
  final double stockMinimo;

  const _ProductoDatos({
    required this.nombre,
    required this.marca,
    required this.presentacion,
    required this.contenido,
    required this.unidadBase,
    required this.unidadesPorEmpaque,
    required this.precioCompra,
    required this.precioVenta,
    required this.precioMayorista,
    required this.stockInicial,
    required this.stockMinimo,
  });
}
