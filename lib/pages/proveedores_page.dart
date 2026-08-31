import 'package:flutter/material.dart';

import '../services/proveedores_service.dart';

class ProveedoresPage extends StatefulWidget {
  const ProveedoresPage({super.key});

  @override
  State<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends State<ProveedoresPage> {
  final ProveedoresService _service = ProveedoresService();

  final TextEditingController _buscarController =
      TextEditingController();

  List<Map<String, dynamic>> proveedores = [];
  List<Map<String, dynamic>> resultados = [];

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarProveedores();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  // ============================================================
  // CARGAR PROVEEDORES
  // ============================================================

  Future<void> cargarProveedores() async {
    try {
      setState(() {
        cargando = true;
      });

      final data = await _service.obtenerProveedores(
        incluirInactivos: true,
      );

      if (!mounted) return;

      setState(() {
        proveedores = data;
        resultados = data;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      mostrarMensaje(
        'Error cargando proveedores:\n$e',
        error: true,
      );
    }
  }

  // ============================================================
  // BUSCAR
  // ============================================================

  void buscarProveedor(String texto) {
    final busqueda = texto.trim().toLowerCase();

    setState(() {
      if (busqueda.isEmpty) {
        resultados = proveedores;
        return;
      }

      resultados = proveedores.where((proveedor) {
        final nombre =
            proveedor['nombre']?.toString().toLowerCase() ?? '';

        final documento =
            proveedor['documento']?.toString().toLowerCase() ?? '';

        final telefono =
            proveedor['telefono']?.toString().toLowerCase() ?? '';

        final contacto =
            proveedor['contacto']?.toString().toLowerCase() ?? '';

        return nombre.contains(busqueda) ||
            documento.contains(busqueda) ||
            telefono.contains(busqueda) ||
            contacto.contains(busqueda);
      }).toList();
    });
  }

  // ============================================================
  // FORMULARIO NUEVO / EDITAR
  // ============================================================

  Future<void> mostrarFormulario({
    Map<String, dynamic>? proveedor,
  }) async {
    final bool editando = proveedor != null;

    final nombreController = TextEditingController(
      text: proveedor?['nombre']?.toString() ?? '',
    );

    final documentoController = TextEditingController(
      text: proveedor?['documento']?.toString() ?? '',
    );

    final telefonoController = TextEditingController(
      text: proveedor?['telefono']?.toString() ?? '',
    );

    final direccionController = TextEditingController(
      text: proveedor?['direccion']?.toString() ?? '',
    );

    final contactoController = TextEditingController(
      text: proveedor?['contacto']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    bool guardando = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                editando
                    ? 'Editar proveedor'
                    : 'Nuevo proveedor',
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nombreController,
                          textCapitalization:
                              TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nombre / Razón social *',
                            prefixIcon:
                                Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Ingrese el nombre del proveedor';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: documentoController,
                          decoration: const InputDecoration(
                            labelText: 'Documento / RUC',
                            prefixIcon:
                                Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: telefonoController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            prefixIcon:
                                Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: contactoController,
                          textCapitalization:
                              TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Persona de contacto',
                            prefixIcon:
                                Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: direccionController,
                          textCapitalization:
                              TextCapitalization.sentences,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                            prefixIcon:
                                Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancelar'),
                ),

                FilledButton.icon(
                  onPressed: guardando
                      ? null
                      : () async {
                          if (!formKey.currentState!
                              .validate()) {
                            return;
                          }

                          setDialogState(() {
                            guardando = true;
                          });

                          try {
                            if (editando) {
                              await _service.actualizarProveedor(
                                id: proveedor['id'].toString(),
                                nombre:
                                    nombreController.text,
                                documento:
                                    documentoController.text,
                                telefono:
                                    telefonoController.text,
                                direccion:
                                    direccionController.text,
                                contacto:
                                    contactoController.text,
                              );
                            } else {
                              await _service.crearProveedor(
                                nombre:
                                    nombreController.text,
                                documento:
                                    documentoController.text,
                                telefono:
                                    telefonoController.text,
                                direccion:
                                    direccionController.text,
                                contacto:
                                    contactoController.text,
                              );
                            }

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            await cargarProveedores();

                            mostrarMensaje(
                              editando
                                  ? 'Proveedor actualizado correctamente.'
                                  : 'Proveedor registrado correctamente.',
                            );
                          } catch (e) {
                            setDialogState(() {
                              guardando = false;
                            });

                            mostrarMensaje(
                              'No se pudo guardar el proveedor:\n$e',
                              error: true,
                            );
                          }
                        },
                  icon: guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    guardando ? 'Guardando...' : 'Guardar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nombreController.dispose();
    documentoController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    contactoController.dispose();
  }

  // ============================================================
  // CAMBIAR ESTADO
  // ============================================================

  Future<void> cambiarEstado(
    Map<String, dynamic> proveedor,
  ) async {
    final bool activo =
        proveedor['activo'] == true;

    final nombre =
        proveedor['nombre']?.toString() ?? 'proveedor';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            activo
                ? 'Desactivar proveedor'
                : 'Activar proveedor',
          ),
          content: Text(
            activo
                ? '¿Deseas desactivar a "$nombre"?\n\n'
                    'No se eliminará de la base de datos.'
                : '¿Deseas activar nuevamente a "$nombre"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: Text(
                activo ? 'Desactivar' : 'Activar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await _service.cambiarEstadoProveedor(
        id: proveedor['id'].toString(),
        activo: !activo,
      );

      await cargarProveedores();

      if (!mounted) return;

      mostrarMensaje(
        activo
            ? 'Proveedor desactivado.'
            : 'Proveedor activado.',
      );
    } catch (e) {
      if (!mounted) return;

      mostrarMensaje(
        'Error cambiando estado:\n$e',
        error: true,
      );
    }
  }

  // ============================================================
  // MENSAJES
  // ============================================================

  void mostrarMensaje(
    String mensaje, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor:
              error ? Colors.red : null,
        ),
      );
  }

  // ============================================================
  // TARJETA PROVEEDOR
  // ============================================================

  Widget _buildProveedorCard(
    Map<String, dynamic> proveedor,
  ) {
    final nombre =
        proveedor['nombre']?.toString() ??
            'Sin nombre';

    final documento =
        proveedor['documento']?.toString() ?? '';

    final telefono =
        proveedor['telefono']?.toString() ?? '';

    final direccion =
        proveedor['direccion']?.toString() ?? '';

    final contacto =
        proveedor['contacto']?.toString() ?? '';

    final activo =
        proveedor['activo'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final movil =
                constraints.maxWidth < 650;

            final informacion = Expanded(
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    child: Icon(
                      activo
                          ? Icons.business
                          : Icons.business_outlined,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                nombre,
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(20),
                                color: activo
                                    ? Colors.green
                                        .withValues(alpha: 0.10)
                                    : Colors.grey
                                        .withValues(alpha: 0.15),
                              ),
                              child: Text(
                                activo
                                    ? 'Activo'
                                    : 'Inactivo',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.bold,
                                  color: activo
                                      ? Colors.green
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        if (documento.isNotEmpty)
                          _dato(
                            Icons.badge_outlined,
                            'Documento',
                            documento,
                          ),

                        if (telefono.isNotEmpty)
                          _dato(
                            Icons.phone_outlined,
                            'Teléfono',
                            telefono,
                          ),

                        if (contacto.isNotEmpty)
                          _dato(
                            Icons.person_outline,
                            'Contacto',
                            contacto,
                          ),

                        if (direccion.isNotEmpty)
                          _dato(
                            Icons.location_on_outlined,
                            'Dirección',
                            direccion,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            final acciones = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () =>
                      mostrarFormulario(
                    proveedor: proveedor,
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),

                IconButton(
                  tooltip: activo
                      ? 'Desactivar'
                      : 'Activar',
                  onPressed: () =>
                      cambiarEstado(proveedor),
                  icon: Icon(
                    activo
                        ? Icons.toggle_on
                        : Icons.toggle_off,
                    size: 30,
                    color: activo
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ],
            );

            if (movil) {
              return Column(
                children: [
                  Row(
                    children: [
                      informacion,
                    ],
                  ),
                  const Divider(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: acciones,
                  ),
                ],
              );
            }

            return Row(
              children: [
                informacion,
                const SizedBox(width: 16),
                acciones,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dato(
    IconData icono,
    String etiqueta,
    String valor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icono,
            size: 17,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 7),
          Text(
            '$etiqueta: ',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              valor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INTERFAZ
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Proveedores',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: cargarProveedores,
            icon: const Icon(Icons.refresh),
          ),

          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo proveedor'),
      ),

      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: cargarProveedores,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(
                          maxWidth: 1200,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gestión de proveedores',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'Registra y administra tus proveedores.',
                              style: TextStyle(
                                color:
                                    Colors.grey.shade600,
                              ),
                            ),

                            const SizedBox(height: 20),

                            TextField(
                              controller:
                                  _buscarController,
                              onChanged:
                                  buscarProveedor,
                              decoration:
                                  InputDecoration(
                                hintText:
                                    'Buscar por nombre, documento, teléfono o contacto...',
                                prefixIcon:
                                    const Icon(
                                  Icons.search,
                                ),
                                suffixIcon:
                                    _buscarController
                                            .text
                                            .isNotEmpty
                                        ? IconButton(
                                            onPressed: () {
                                              _buscarController
                                                  .clear();
                                              buscarProveedor(
                                                  '');
                                            },
                                            icon:
                                                const Icon(
                                              Icons.clear,
                                            ),
                                          )
                                        : null,
                                border:
                                    const OutlineInputBorder(),
                              ),
                            ),

                            const SizedBox(height: 20),

                            if (resultados.isEmpty)
                              Card(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(30),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.business_outlined,
                                          size: 55,
                                          color: Colors
                                              .grey.shade400,
                                        ),
                                        const SizedBox(
                                            height: 12),
                                        const Text(
                                          'No hay proveedores registrados.',
                                        ),
                                        const SizedBox(
                                            height: 12),
                                        FilledButton.icon(
                                          onPressed: () =>
                                              mostrarFormulario(),
                                          icon: const Icon(
                                            Icons.add,
                                          ),
                                          label: const Text(
                                            'Registrar proveedor',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...resultados.map(
                                _buildProveedorCard,
                              ),

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}