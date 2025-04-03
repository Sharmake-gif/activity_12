import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // It initialized Firebase before running the app
  await Firebase.initializeApp();
  runApp(InventoryApp());
}

class InventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InventoryHomePage(title: 'Inventory Home Page'),
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  final String title;
  InventoryHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _InventoryHomePageState createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  // Reference to the Firestore collection
  final CollectionReference itemsCollection =
      FirebaseFirestore.instance.collection('items');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      // Use a StreamBuilder for real-time updates from Firestore
      body: StreamBuilder<QuerySnapshot>(
        stream: itemsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final List<DocumentSnapshot> documents = snapshot.data!.docs;
          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              var item = documents[index];
              return ListTile(
                title: Text(item['name'] ?? 'No Name'),
                subtitle: Text(item['description'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit button navigates to the EditItemScreen
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditItemScreen(
                              itemId: item.id,
                              currentName: item['name'],
                              currentDescription: item['description'],
                            ),
                          ),
                        );
                      },
                    ),
                    // Delete button removes the item from Firestore
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        await itemsCollection.doc(item.id).delete();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      // Floating button navigates to the AddItemScreen
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => AddItemScreen()));
        },
        tooltip: 'Add Item',
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddItemScreen extends StatefulWidget {
  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Reference to the Firestore collection
  final CollectionReference itemsCollection =
      FirebaseFirestore.instance.collection('items');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Inventory Item'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Field for item name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Item Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter item name' : null,
              ),
              // Field for item description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 20),
              // Button to add the item to Firestore
              ElevatedButton(
                child: Text('Add Item'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await itemsCollection.add({
                      'name': _nameController.text,
                      'description': _descriptionController.text,
                      'created_at': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditItemScreen extends StatefulWidget {
  final String itemId;
  final String currentName;
  final String currentDescription;

  EditItemScreen({
    required this.itemId,
    required this.currentName,
    required this.currentDescription,
  });

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  final CollectionReference itemsCollection =
      FirebaseFirestore.instance.collection('items');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _descriptionController =
        TextEditingController(text: widget.currentDescription);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Inventory Item'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Item Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter item name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 20),
              // This button is to update the item in Firestore
              ElevatedButton(
                child: Text('Update Item'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await itemsCollection.doc(widget.itemId).update({
                      'name': _nameController.text,
                      'description': _descriptionController.text,
                      'updated_at': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  
