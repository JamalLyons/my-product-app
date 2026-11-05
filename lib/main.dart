import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const ProductApp());
  } catch (error) {
    runApp(ProductApp(firebaseSetupError: error.toString()));
  }
}

class ProductApp extends StatelessWidget {
  const ProductApp({super.key, this.firebaseSetupError});

  final String? firebaseSetupError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autumn Product Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      home: ProductPage(firebaseSetupError: firebaseSetupError),
    );
  }
}

class ProductPage extends StatefulWidget {
  const ProductPage({super.key, this.firebaseSetupError});

  final String? firebaseSetupError;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final _searchController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  late final CollectionReference<Map<String, dynamic>> _products;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _productStream;

  String _query = '';
  String? _filterError;

  @override
  void initState() {
    super.initState();
    if (widget.firebaseSetupError == null) {
      _products = FirebaseFirestore.instance.collection('products');
      _productStream = _products.snapshots();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  String? _validatePriceRange() {
    final minText = _minController.text.trim();
    final maxText = _maxController.text.trim();
    final minPrice = minText.isEmpty ? null : double.tryParse(minText);
    final maxPrice = maxText.isEmpty ? null : double.tryParse(maxText);

    if (minText.isNotEmpty &&
        (minPrice == null || !minPrice.isFinite || minPrice < 0)) {
      return 'Minimum price must be a finite number greater than or equal to 0.';
    }
    if (maxText.isNotEmpty &&
        (maxPrice == null || !maxPrice.isFinite || maxPrice < 0)) {
      return 'Maximum price must be a finite number greater than or equal to 0.';
    }
    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      return 'Minimum price cannot exceed maximum price.';
    }
    return null;
  }

  void _updatePriceFilter() {
    setState(() => _filterError = _validatePriceRange());
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _minController.clear();
      _maxController.clear();
      _query = '';
      _filterError = null;
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  Future<void> _editProduct(
    QueryDocumentSnapshot<Map<String, dynamic>>? document,
  ) async {
    final data = document?.data();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ProductEditorDialog(
        initialName: data?['name'] is String ? data!['name'] as String : '',
        initialPrice: data?['price'] is num
            ? (data!['price'] as num).toString()
            : '',
        onSave: (name, price) async {
          final product = <String, dynamic>{'name': name, 'price': price};
          if (document == null) {
            await _products.add(product);
          } else {
            await _products.doc(document.id).update(product);
          }
        },
      ),
    );

    if (saved == true && mounted) {
      _showMessage(document == null ? 'Product created.' : 'Product updated.');
    }
  }

  Future<void> _deleteProduct(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Delete "$name" (ID: $id)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _products.doc(id).delete();
      if (mounted) _showMessage('Product deleted.');
    } on FirebaseException catch (error) {
      if (mounted) {
        _showMessage(
          'Delete failed (${error.code}). Check your connection and access.',
          isError: true,
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Delete failed. Please try again.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupError = widget.firebaseSetupError;

    return Scaffold(
      appBar: AppBar(title: const Text('Autumn Product Manager')),
      body: setupError != null
          ? _FirebaseSetupMessage(error: setupError)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search by name',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {
                          _query = value;
                        }),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _minController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Min price',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => _updatePriceFilter(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _maxController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Max price',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => _updatePriceFilter(),
                            ),
                          ),
                          TextButton(
                            onPressed: _resetFilters,
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      if (_filterError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _filterError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: _buildProductList()),
              ],
            ),
      floatingActionButton: setupError == null
          ? FloatingActionButton(
              onPressed: () => _editProduct(null),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildProductList() {
    if (_filterError != null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Correct the price filters to show matching products.'),
        ),
      );
    }

    final minText = _minController.text.trim();
    final maxText = _maxController.text.trim();
    final minPrice = minText.isEmpty ? null : double.tryParse(minText);
    final maxPrice = maxText.isEmpty ? null : double.tryParse(maxText);
    final normalizedQuery = _query.trim().toLowerCase();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _productStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Products could not load. Check your connection and Firestore access.',
              textAlign: TextAlign.center,
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final documents = snapshot.data!.docs;
        if (documents.isEmpty) {
          return const Center(
            child: Text('No products yet. Add one to begin.'),
          );
        }

        final entries = documents.map(_ProductEntry.fromDocument).toList();
        final malformed = entries.where((entry) => !entry.isValid).toList();
        final products = entries.where((entry) {
          if (!entry.isValid) return false;
          final name = entry.name!.trim().toLowerCase();
          final price = entry.price!;
          return name.contains(normalizedQuery) &&
              (minPrice == null || price >= minPrice) &&
              (maxPrice == null || price <= maxPrice);
        }).toList();

        if (products.isEmpty && malformed.isEmpty) {
          return const Center(
            child: Text(
              'No products found. Try different search/filter criteria, or Reset.',
            ),
          );
        }

        return ListView(
          children: [
            for (final product in products)
              ListTile(
                title: Text(product.name!),
                subtitle: Text(
                  '\$${product.price!.toStringAsFixed(2)}  •  ID: ${product.id}',
                ),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Edit ${product.name}',
                      onPressed: () => _editProduct(product.document),
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      tooltip: 'Delete ${product.name}',
                      onPressed: () =>
                          _deleteProduct(product.id, product.name!),
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
              ),
            for (final product in malformed)
              ListTile(
                leading: Icon(
                  Icons.warning_amber,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('Malformed product record'),
                subtitle: Text('${product.problem} ID: ${product.id}'),
                trailing: IconButton(
                  tooltip: 'Delete malformed record',
                  onPressed: () =>
                      _deleteProduct(product.id, 'malformed record'),
                  icon: const Icon(Icons.delete),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProductEntry {
  const _ProductEntry({
    required this.document,
    required this.id,
    this.name,
    this.price,
    this.problem,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final String id;
  final String? name;
  final num? price;
  final String? problem;

  bool get isValid => name != null && price != null;

  factory _ProductEntry.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final rawName = data['name'];
    final rawPrice = data['price'];

    if (rawName is! String || rawName.trim().isEmpty) {
      return _ProductEntry(
        document: document,
        id: document.id,
        problem: 'Name is missing or is not a nonempty string.',
      );
    }
    if (rawPrice is! num || !rawPrice.isFinite || rawPrice < 0) {
      return _ProductEntry(
        document: document,
        id: document.id,
        problem: 'Price is missing or is not a finite nonnegative number.',
      );
    }
    return _ProductEntry(
      document: document,
      id: document.id,
      name: rawName,
      price: rawPrice,
    );
  }
}

class ProductEditorDialog extends StatefulWidget {
  const ProductEditorDialog({
    required this.initialName,
    required this.initialPrice,
    required this.onSave,
    super.key,
  });

  final String initialName;
  final String initialPrice;
  final Future<void> Function(String name, double price) onSave;

  @override
  State<ProductEditorDialog> createState() => _ProductEditorDialogState();
}

class _ProductEditorDialogState extends State<ProductEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _priceController = TextEditingController(text: widget.initialPrice);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final price = double.parse(_priceController.text.trim());

    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(_nameController.text.trim(), price);
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError =
            'Save failed (${error.code}). Check your connection and Firestore access.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Save failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(
          widget.initialName.isEmpty && widget.initialPrice.isEmpty
              ? 'Create product'
              : 'Edit product',
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a nonempty product name.'
                    : null,
              ),
              TextFormField(
                controller: _priceController,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Price'),
                validator: (value) {
                  final price = double.tryParse(value?.trim() ?? '');
                  return price == null || !price.isFinite || price < 0
                      ? 'Enter a finite price greater than or equal to 0.'
                      : null;
                },
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _saveError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_saving) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                const Text('Saving product…'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ],
      ),
    );
  }
}

class _FirebaseSetupMessage extends StatelessWidget {
  const _FirebaseSetupMessage({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Firebase is not configured yet. From the project root, run '
              '`flutterfire configure --platforms=android`, then restart the app.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SelectableText('Initialization detail: $error'),
          ],
        ),
      ),
    );
  }
}
