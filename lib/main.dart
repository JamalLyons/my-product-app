import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    runApp(const ProductApp());
  } catch (e) {
    runApp(ProductApp(firebaseSetupError: e.toString()));
  }
}

class ProductApp extends StatelessWidget {
  const ProductApp({super.key, this.firebaseSetupError});
  final String? firebaseSetupError;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Autumn Product Manager', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
    home: ProductPage(firebaseSetupError: firebaseSetupError),
  );
}

class ProductPage extends StatefulWidget {
  const ProductPage({super.key, this.firebaseSetupError});
  final String? firebaseSetupError;
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  CollectionReference<Map<String, dynamic>> get products =>
      FirebaseFirestore.instance.collection('products');
  final search = TextEditingController(), min = TextEditingController(), max = TextEditingController();
  String query = ''; String? filterError;
  @override
  void dispose() { search.dispose(); min.dispose(); max.dispose(); super.dispose(); }
  String? validate() {
    final a = min.text.trim(), b = max.text.trim(); final lo = a.isEmpty ? null : double.tryParse(a), hi = b.isEmpty ? null : double.tryParse(b);
    if (a.isNotEmpty && (lo == null || !lo.isFinite || lo < 0)) return 'Min price must be a finite number ≥ 0';
    if (b.isNotEmpty && (hi == null || !hi.isFinite || hi < 0)) return 'Max price must be a finite number ≥ 0';
    if (lo != null && hi != null && lo > hi) return 'Min price cannot exceed max price';
    return null;
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Autumn Product Manager')),
    body: widget.firebaseSetupError != null
      ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Firebase is not configured. Add firebase_options.dart and initialize Firebase for your project to connect the product manager.', textAlign: TextAlign.center)))
      : Column(children: [Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        TextField(controller: search, decoration: const InputDecoration(labelText: 'Search by name', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (v) => setState(() { query = v; filterError = null; })),
        const SizedBox(height: 8), Row(children: [Expanded(child: TextField(controller: min, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Min price', border: OutlineInputBorder()), onChanged: (_) => setState(() => filterError = validate()))), const SizedBox(width: 8), Expanded(child: TextField(controller: max, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Max price', border: OutlineInputBorder()), onChanged: (_) => setState(() => filterError = validate()))), TextButton(onPressed: () => setState(() { search.clear(); min.clear(); max.clear(); query = ''; filterError = null; }), child: const Text('Reset'))]),
        if (filterError != null) Text(filterError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ])), const Divider(height: 1), Expanded(child: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream: products.snapshots(), builder: (context, snap) {
        if (snap.hasError) return const Center(child: Text('Products could not load. Check connection and permissions.'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final lo = min.text.trim().isEmpty ? null : double.tryParse(min.text.trim()), hi = max.text.trim().isEmpty ? null : double.tryParse(max.text.trim());
        final items = snap.data!.docs.where((d) { final x=d.data(), n=x['name'], p=x['price']; return filterError == null && n is String && p is num && p.isFinite && p >= 0 && n.toLowerCase().contains(query.trim().toLowerCase()) && (lo == null || p >= lo) && (hi == null || p <= hi); }).toList();
        if (snap.data!.docs.isEmpty) return const Center(child: Text('No products yet. Add one to begin.'));
        if (items.isEmpty) return const Center(child: Text('No products found. Try different search/filter criteria, or Reset.'));
        return ListView(children: items.map((d) { final x=d.data(); return ListTile(title: Text(x['name']), subtitle: Text('\$${(x['price'] as num).toStringAsFixed(2)}  •  ID: ${d.id}'), trailing: Wrap(children: [IconButton(onPressed: () => edit(d), icon: const Icon(Icons.edit)), IconButton(onPressed: () async { if (await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Delete product?'), content: Text('Delete ${d.id}?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))])) == true) await products.doc(d.id).delete(); }, icon: const Icon(Icons.delete))])); }).toList());
      })),]),
    floatingActionButton: FloatingActionButton(onPressed: () => edit(null), child: const Icon(Icons.add)),
  );
  Future<void> edit(QueryDocumentSnapshot<Map<String,dynamic>>? d) async { final name=TextEditingController(text: d?.data()['name'] as String? ?? ''), price=TextEditingController(text: d?.data()['price']?.toString() ?? ''); await showDialog<void>(context: context, builder: (c) => AlertDialog(title: Text(d == null ? 'Create product' : 'Edit product'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')), TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price'))]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')), TextButton(onPressed: () async { final p=double.tryParse(price.text.trim()); if (name.text.trim().isEmpty || p == null || !p.isFinite || p < 0) return; final data={'name':name.text.trim(),'price':p}; if (d == null) { await products.add(data); } else { await products.doc(d.id).update(data); } if (c.mounted) Navigator.pop(c); }, child: const Text('Save'))])); name.dispose(); price.dispose(); }
}
