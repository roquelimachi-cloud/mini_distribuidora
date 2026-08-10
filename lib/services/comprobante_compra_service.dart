import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ComprobanteCompraService {
  // ============================================================
  // GENERAR PDF DE COMPRA
  // ============================================================

  static Future<Uint8List> generarComprobante({
    required Map<String, dynamic> compra,
    required List<Map<String, dynamic>> detalle,
  }) async {
    final pdf = pw.Document();

    final numero =
        compra['numero_compra']?.toString() ?? 'Sin número';

    final proveedorData =
        compra['proveedores'];

    String proveedor = 'Sin proveedor';
    String documento = '';
    String telefono = '';

    if (proveedorData is Map) {
      proveedor =
          proveedorData['nombre']?.toString() ??
              'Sin proveedor';

      documento =
          proveedorData['documento']?.toString() ??
              '';

      telefono =
          proveedorData['telefono']?.toString() ??
              '';
    }

    final metodoPago =
        compra['metodo_pago']?.toString() ?? '-';

    final estadoOriginal =
        compra['estado']?.toString() ?? 'activa';

    final estado =
        estadoOriginal.toLowerCase() == 'completada'
            ? 'activa'
            : estadoOriginal.toLowerCase() == 'completed'
                ? 'activa'
                : estadoOriginal;

    final observaciones =
        compra['observaciones']?.toString() ?? '';

    // ==========================================================
    // TOTALES
    // El subtotal se calcula desde el detalle para evitar
    // mostrar S/ 0.00 cuando el campo compras.subtotal no esté
    // correctamente poblado.
    // ==========================================================

    double subtotal = 0;

    for (final item in detalle) {
      final cantidad =
          (item['cantidad'] as num?)?.toDouble() ?? 0;

      final precio =
          (item['precio_unitario'] as num?)?.toDouble() ?? 0;

      final subtotalItem =
          (item['subtotal'] as num?)?.toDouble() ??
          (cantidad * precio);

      subtotal += subtotalItem;
    }

    final descuento =
        (compra['descuento'] as num?)
                ?.toDouble() ??
            0;

    // Usamos el total registrado en la compra cuando existe.
    // Si no existe, calculamos subtotal - descuento.
    final totalRegistrado =
        (compra['total'] as num?)?.toDouble();

    final total =
        totalRegistrado ??
        (subtotal - descuento);

    final fecha =
        _formatearFecha(
      compra['created_at'],
    );

    // ==========================================================
    // COLORES
    // ==========================================================

    final colorPrincipal =
        PdfColor.fromHex('#1F4E79');

    final colorGris =
        PdfColor.fromHex('#666666');

    final colorRojo =
        PdfColor.fromHex('#C62828');

    // ==========================================================
    // PDF
    // ==========================================================

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),

        header: (context) {
          return pw.Container(
            margin:
                const pw.EdgeInsets.only(
              bottom: 15,
            ),
            child: pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment
                      .spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment
                          .start,
                  children: [
                    pw.Text(
                      'MR',
                      style:
                          pw.TextStyle(
                        fontSize: 28,
                        fontWeight:
                            pw.FontWeight.bold,
                        color:
                            colorPrincipal,
                      ),
                    ),
                    pw.Text(
                      'COMPROBANTE DE COMPRA',
                      style:
                          pw.TextStyle(
                        fontSize: 11,
                        color:
                            colorGris,
                        fontWeight:
                            pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                pw.Container(
                  padding:
                      const pw.EdgeInsets
                          .symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration:
                      pw.BoxDecoration(
                    border: pw.Border.all(
                      color:
                          colorPrincipal,
                    ),
                    borderRadius:
                        pw.BorderRadius
                            .circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment
                            .end,
                    children: [
                      pw.Text(
                        numero,
                        style:
                            pw.TextStyle(
                          fontSize: 14,
                          fontWeight:
                              pw.FontWeight
                                  .bold,
                          color:
                              colorPrincipal,
                        ),
                      ),
                      pw.SizedBox(
                        height: 3,
                      ),
                      pw.Text(
                        fecha,
                        style:
                            pw.TextStyle(
                          fontSize: 9,
                          color:
                              colorGris,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },

        footer: (context) {
          return pw.Container(
            margin:
                const pw.EdgeInsets.only(
              top: 15,
            ),
            padding:
                const pw.EdgeInsets.only(
              top: 8,
            ),
            decoration:
                const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                  color:
                      PdfColors.grey300,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment
                      .spaceBetween,
              children: [
                pw.Text(
                  'MR - Comprobante de compra',
                  style:
                      pw.TextStyle(
                    fontSize: 8,
                    color:
                        colorGris,
                  ),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style:
                      pw.TextStyle(
                    fontSize: 8,
                    color:
                        colorGris,
                  ),
                ),
              ],
            ),
          );
        },

        build: (context) {
          return [
            // ==================================================
            // INFORMACIÓN DEL PROVEEDOR
            // ==================================================

            pw.Container(
              padding:
                  const pw.EdgeInsets.all(
                12,
              ),
              decoration:
                  pw.BoxDecoration(
                color:
                    PdfColors.grey100,
                borderRadius:
                    pw.BorderRadius
                        .circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment
                        .start,
                children: [
                  pw.Text(
                    'DATOS DEL PROVEEDOR',
                    style:
                        pw.TextStyle(
                      fontSize: 11,
                      fontWeight:
                          pw.FontWeight
                              .bold,
                      color:
                          colorPrincipal,
                    ),
                  ),

                  pw.SizedBox(
                    height: 8,
                  ),

                  pw.Row(
                    children: [
                      pw.Expanded(
                        child:
                            _dato(
                          'Proveedor',
                          proveedor,
                        ),
                      ),
                      pw.Expanded(
                        child:
                            _dato(
                          'Documento',
                          documento
                                  .isEmpty
                              ? '-'
                              : documento,
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(
                    height: 5,
                  ),

                  pw.Row(
                    children: [
                      pw.Expanded(
                        child:
                            _dato(
                          'Teléfono',
                          telefono
                                  .isEmpty
                              ? '-'
                              : telefono,
                        ),
                      ),
                      pw.Expanded(
                        child:
                            _dato(
                          'Método de pago',
                          metodoPago,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(
              height: 20,
            ),

            // ==================================================
            // ESTADO
            // ==================================================

            pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment
                      .end,
              children: [
                pw.Container(
                  padding:
                      const pw.EdgeInsets
                          .symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration:
                      pw.BoxDecoration(
                    color:
                        estado.toLowerCase() ==
                                'anulada'
                            ? PdfColors.red100
                            : PdfColors.green100,
                    borderRadius:
                        pw.BorderRadius
                            .circular(20),
                  ),
                  child: pw.Text(
                    estado
                        .toUpperCase(),
                    style:
                        pw.TextStyle(
                      fontSize: 9,
                      fontWeight:
                          pw.FontWeight
                              .bold,
                      color:
                          estado.toLowerCase() ==
                                  'anulada'
                              ? colorRojo
                              : PdfColors
                                  .green800,
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(
              height: 12,
            ),

            // ==================================================
            // PRODUCTOS
            // ==================================================

            pw.Text(
              'DETALLE DE PRODUCTOS',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight:
                    pw.FontWeight.bold,
                color:
                    colorPrincipal,
              ),
            ),

            pw.SizedBox(
              height: 8,
            ),

            pw.TableHelper.fromTextArray(
              headers: const [
                'Producto',
                'Código',
                'Cantidad',
                'P. Unit.',
                'Subtotal',
              ],
              data: detalle.map(
                (item) {
                  final producto =
                      item['productos'];

                  String nombre =
                      'Producto';

                  String codigo = '';

                  if (producto is Map) {
                    nombre =
                        producto['nombre']
                                ?.toString() ??
                            'Producto';

                    codigo =
                        producto['codigo']
                                ?.toString() ??
                            '';
                  }

                  final cantidad =
                      (item['cantidad']
                                  as num?)
                              ?.toDouble() ??
                          0;

                  final precio =
                      (item[
                                      'precio_unitario']
                                  as num?)
                              ?.toDouble() ??
                          0;

                  final subtotalItem =
                      (item['subtotal']
                                  as num?)
                              ?.toDouble() ??
                          (cantidad *
                              precio);

                  return [
                    nombre,
                    codigo.isEmpty
                        ? '-'
                        : codigo,
                    cantidad
                        .toStringAsFixed(0),
                    'S/ ${precio.toStringAsFixed(2)}',
                    'S/ ${subtotalItem.toStringAsFixed(2)}',
                  ];
                },
              ).toList(),
              headerStyle:
                  pw.TextStyle(
                fontWeight:
                    pw.FontWeight.bold,
                fontSize: 9,
                color:
                    PdfColors.white,
              ),
              headerDecoration:
                  pw.BoxDecoration(
                color:
                    colorPrincipal,
              ),
              cellStyle:
                  const pw.TextStyle(
                fontSize: 8,
              ),
              cellPadding:
                  const pw.EdgeInsets.all(
                6,
              ),
              border:
                  pw.TableBorder.all(
                color:
                    PdfColors.grey300,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(
                  3.2,
                ),
                1: const pw.FlexColumnWidth(
                  1.5,
                ),
                2: const pw.FlexColumnWidth(
                  1.2,
                ),
                3: const pw.FlexColumnWidth(
                  1.5,
                ),
                4: const pw.FlexColumnWidth(
                  1.7,
                ),
              },
            ),

            pw.SizedBox(
              height: 20,
            ),

            // ==================================================
            // TOTALES
            // ==================================================

            pw.Align(
              alignment:
                  pw.Alignment.centerRight,
              child: pw.Container(
                width: 260,
                child: pw.Column(
                  children: [
                    _filaTotal(
                      'Subtotal',
                      subtotal,
                    ),
                    _filaTotal(
                      'Descuento',
                      descuento,
                    ),
                    pw.Divider(
                      color:
                          PdfColors.grey400,
                    ),
                    _filaTotal(
                      'TOTAL',
                      total,
                      destacado: true,
                      color:
                          colorPrincipal,
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // OBSERVACIONES
            // ==================================================

            if (observaciones
                .trim()
                .isNotEmpty) ...[
              pw.SizedBox(
                height: 25,
              ),
              pw.Text(
                'OBSERVACIONES',
                style:
                    pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      pw.FontWeight.bold,
                  color:
                      colorPrincipal,
                ),
              ),
              pw.SizedBox(
                height: 6,
              ),
              pw.Container(
                width:
                    double.infinity,
                padding:
                    const pw.EdgeInsets
                        .all(10),
                decoration:
                    pw.BoxDecoration(
                  border:
                      pw.Border.all(
                    color:
                        PdfColors.grey300,
                  ),
                  borderRadius:
                      pw.BorderRadius
                          .circular(4),
                ),
                child: pw.Text(
                  observaciones,
                  style:
                      const pw.TextStyle(
                    fontSize: 9,
                  ),
                ),
              ),
            ],

            pw.SizedBox(
              height: 30,
            ),

            pw.Center(
              child: pw.Text(
                'Documento generado por el sistema MR',
                style:
                    pw.TextStyle(
                  fontSize: 8,
                  color:
                      colorGris,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ============================================================
  // DATO
  // ============================================================

  static pw.Widget _dato(
    String titulo,
    String valor,
  ) {
    return pw.Row(
      crossAxisAlignment:
          pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$titulo: ',
          style:
              pw.TextStyle(
            fontSize: 8,
            fontWeight:
                pw.FontWeight.bold,
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            valor,
            style:
                const pw.TextStyle(
              fontSize: 8,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILA TOTAL
  // ============================================================

  static pw.Widget _filaTotal(
    String titulo,
    double valor, {
    bool destacado = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding:
          const pw.EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment
                .spaceBetween,
        children: [
          pw.Text(
            titulo,
            style:
                pw.TextStyle(
              fontSize:
                  destacado ? 12 : 9,
              fontWeight:
                  destacado
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
              color: color,
            ),
          ),
          pw.Text(
            'S/ ${valor.toStringAsFixed(2)}',
            style:
                pw.TextStyle(
              fontSize:
                  destacado ? 13 : 9,
              fontWeight:
                  pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FECHA
  // ============================================================

  static String _formatearFecha(
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
          numero
              .toString()
              .padLeft(2, '0');

      return '${dos(fecha.day)}/'
          '${dos(fecha.month)}/'
          '${fecha.year} '
          '${dos(fecha.hour)}:'
          '${dos(fecha.minute)}';
    } catch (_) {
      return valor.toString();
    }
  }
}