import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'db_helper.dart';

class ExcelExporter {
  static Future<void> exportAndShare() async {
    // Fetch strongly-typed List<Item> using getItems()
    final items = await DatabaseHelper.instance.getItems();
    var excel = Excel.createExcel();
    
    // Set up sheet
    Sheet sheet = excel['Inventory'];

    // Header row
    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Barcode'),
      TextCellValue('Name'),
      TextCellValue('Quantity'),
      TextCellValue('Date Submitted'),
    ]);

    // Data rows using Item properties
    for (var item in items) {
      sheet.appendRow([
        IntCellValue(item.id ?? 0),
        TextCellValue(item.barcode),
        TextCellValue(item.name),
        IntCellValue(item.quantity),
        TextCellValue(item.dateSubmitted),
      ]);
    }

    // Save and share file
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/inventory_export.xlsx');
    final bytes = excel.encode();
    
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Exported Inventory Data');
    }
  }
}