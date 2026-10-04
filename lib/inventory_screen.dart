import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'db_helper.dart';
import 'excel_service.dart'; // Ensure this matches your ExcelExporter file name
import 'item.dart';
import 'scanner_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Item> _allItems = [];
  List<Item> _filteredItems = [];
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() async {
    final data = await DatabaseHelper.instance.getItems();
    setState(() {
      _allItems = data;
      _filterItems();
    });
  }

  void _filterItems() {
    if (_searchQuery.isEmpty) {
      _filteredItems = List.from(_allItems);
    } else {
      _filteredItems = _allItems.where((item) {
        return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.barcode.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  void _delete(int id) async {
    await DatabaseHelper.instance.deleteItem(id);
    _refreshList();
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('MMM d, yyyy - h:mm a').format(date);
    } catch (e) {
      return 'Unknown Date';
    }
  }

  // Handle DB Export
  Future<void> _handleExportDB() async {
    Navigator.pop(context); // Close Drawer
    try {
      await DatabaseHelper.instance.exportDatabaseFile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export DB: $e')),
        );
      }
    }
  }

  // Handle DB Import
  Future<void> _handleImportDB() async {
    Navigator.pop(context); // Close Drawer
    setState(() => _isLoading = true);
    try {
      bool success = await DatabaseHelper.instance.importDatabaseFile();
      if (success) {
        _refreshList();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Database imported successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import DB: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Handle Excel Export
  Future<void> _handleExportExcel() async {
    Navigator.pop(context); // Close Drawer
    setState(() => _isLoading = true);
    try {
      await ExcelExporter.exportAndShare();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Excel: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
      ),
      // --- SIDEBAR (DRAWER) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Inventory App',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Database Management',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.file_upload_outlined, color: Colors.blue),
              title: const Text('Backup Database (.db)'),
              subtitle: const Text('Export database to move to another phone'),
              onTap: _handleExportDB,
            ),
            ListTile(
              leading:
                  const Icon(Icons.file_download_outlined, color: Colors.green),
              title: const Text('Restore Database (.db)'),
              subtitle: const Text('Import database from backup file'),
              onTap: _handleImportDB,
            ),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.table_chart_outlined, color: Colors.teal),
              title: const Text('Export to Excel (.xlsx)'),
              subtitle: const Text('Share database as a spreadsheet'),
              onTap: _handleExportExcel,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search items...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _filterItems();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _filteredItems.isEmpty
                      ? const Center(child: Text('No items found.'))
                      : ListView.builder(
                          itemCount: _filteredItems.length,
                          itemBuilder: (ctx, idx) {
                            final item = _filteredItems[idx];
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text(
                                'Code: ${item.barcode}\nAdded: ${_formatDate(item.dateSubmitted)}',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Qty: ${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      if (item.id != null) {
                                        _delete(item.id!);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScannerScreen()),
          );
          _refreshList();
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
