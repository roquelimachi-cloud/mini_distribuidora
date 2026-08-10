import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ComprobanteVentaService {
  // ============================================================
  // GENERAR PDF DE VENTA
  // ============================================================

  static Future<Uint8List> generarComprobante({
    required Map<String, dynamic> venta,
    required List<Map<String, dynamic>> detalle,
  }) async {
    final pdf = pw.Document();

    final numero =
        venta['numero_venta']?.toString() ?? 'Sin número';

    final metodoPago =
        venta['metodo_pago']?.toString() ?? '-';

    final estado =
        venta['estado']?.toString() ?? 'completada';

    final observaciones =
        venta['observaciones']?.toString() ?? '';

    final subtotal =
        _numero(venta['subtotal']);

    final descuento =
        _numero(venta['descuento']);

    final total =
        _numero(venta['total']);

    final fecha = _formatearFecha(
      venta['fecha'] ?? venta['created_at'],
    );

    final colorPrincipal =
        PdfColor.fromHex('#1F4E79');

    final colorGris =
        PdfColor.fromHex('#666666');

    final colorRojo =
        PdfColor.fromHex('#C62828');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),

        header: (context) {
          return pw.Container(
            margin:
                const pw.EdgeInsets.only(bottom: 15),
            child: pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MR',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight:
                            pw.FontWeight.bold,
                        color: colorPrincipal,
                      ),
                    ),
                    pw.Text(
                      'COMPROBANTE DE VENTA',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: colorGris,
                        fontWeight:
                            pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: colorPrincipal,
                    ),
                    borderRadius:
                        pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        numero,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight:
                              pw.FontWeight.bold,
                          color: colorPrincipal,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        fecha,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: colorGris,
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
                const pw.EdgeInsets.only(top: 15),
            padding:
                const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                  color: PdfColors.grey300,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'MR - Comprobante de venta',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: colorGris,
                  ),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: colorGris,
                  ),
                ),
              ],
            ),
          );
        },

        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius:
                  pw.BorderRadius.circular(5),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Cliente',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: colorGris,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Cliente no registrado',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight:
                              pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Método de pago',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: colorGris,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      metodoPago,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight:
                            pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 18),

          pw.Text(
            'Detalle de productos',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: colorPrincipal,
            ),
          ),

          pw.SizedBox(height: 8),

          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 0.5,
            ),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 8,
            ),
            headerDecoration: pw.BoxDecoration(
              color: colorPrincipal,
            ),
            cellStyle: const pw.TextStyle(
              fontSize: 8,
            ),
            cellPadding:
                const pw.EdgeInsets.all(6),
            headers: const [
              'Producto',
              'Código',
              'Cant.',
              'P. Unit.',
              'Subtotal',
            ],
            data: detalle.map((item) {
              final cantidad =
                  _numero(item['cantidad']);

              final precio =
                  _numero(item['precio_unitario']);

              final subtotalItem =
                  _numero(item['subtotal']);

              final producto =
                  item['productos'];

              String nombre = 'Producto';
              String codigo = '';

              if (producto is Map) {
                nombre =
                    producto['nombre']?.toString() ??
                        'Producto';
                codigo =
                    producto['codigo']?.toString() ??
                        '';
              }

              return [
                nombre,
                codigo,
                cantidad.toStringAsFixed(0),
                'S/ ${precio.toStringAsFixed(2)}',
                'S/ ${subtotalItem.toStringAsFixed(2)}',
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 18),

          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 230,
              child: pw.Column(
                children: [
                  _filaTotal(
                    'Subtotal',
                    subtotal,
                  ),
                  pw.SizedBox(height: 5),
                  _filaTotal(
                    'Descuento',
                    descuento,
                    color:
                        descuento > 0
                            ? colorRojo
                            : colorGris,
                  ),
                  pw.Divider(),
                  _filaTotal(
                    'TOTAL',
                    total,
                    destacado: true,
                    color: colorPrincipal,
                  ),
                ],
              ),
            ),
          ),

          if (observaciones.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              'Observaciones',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              observaciones,
              style: const pw.TextStyle(
                fontSize: 9,
              ),
            ),
          ],

          pw.SizedBox(height: 20),

          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColors.grey300,
              ),
              borderRadius:
                  pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Estado',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: colorGris,
                  ),
                ),
                pw.Text(
                  estado.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight:
                        pw.FontWeight.bold,
                    color:
                        estado.toLowerCase() ==
                                'anulada'
                            ? colorRojo
                            : colorPrincipal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _filaTotal(
    String etiqueta,
    double valor, {
    bool destacado = false,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment:
          pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          etiqueta,
          style: pw.TextStyle(
            fontSize: destacado ? 11 : 9,
            fontWeight:
                destacado
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
            color: color ?? PdfColors.grey700,
          ),
        ),
        pw.Text(
          'S/ ${valor.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: destacado ? 12 : 9,
            fontWeight:
                destacado
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
            color: color ?? PdfColors.grey800,
          ),
        ),
      ],
    );
  }

  static double _numero(dynamic valor) {
    if (valor is num) {
      return valor.toDouble();
    }

    return double.tryParse(
          valor?.toString() ?? '0',
        ) ??
        0;
  }

  static String _formatearFecha(dynamic valor) {
    final fecha = DateTime.tryParse(
      valor?.toString() ?? '',
    );

    if (fecha == null) {
      return 'Sin fecha';
    }

    final dia =
        fecha.day.toString().padLeft(2, '0');
    final mes =
        fecha.month.toString().padLeft(2, '0');
    final anio =
        fecha.year.toString();

    final hora =
        fecha.hour.toString().padLeft(2, '0');
    final minuto =
        fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
  }
}
