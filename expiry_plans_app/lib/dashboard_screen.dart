import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_item_screen.dart';
import 'main.dart'; // To go back to Sign Up screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _items = [];
  String _selectedFilter = "All";
  final int _currentUserId = 1; 

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8080/items'));
      if (response.statusCode == 200) {
        setState(() {
          _items = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("Error fetching items: $e");
    }
  }

  Future<void> _deleteItem(int itemId) async {
    try {
      final response = await http.delete(Uri.parse('http://10.0.2.2:8080/items/delete/$itemId'));
      if (response.statusCode == 200) {
        _fetchItems();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item deleted")));
      }
    } catch (e) { print("Error: $e"); }
  }

  Color _getUrgencyColor(String dateString) {
    DateTime expiryDate = DateTime.parse(dateString);
    int daysLeft = expiryDate.difference(DateTime.now()).inDays;

    if (daysLeft < 3) return Colors.red.shade100;    
    if (daysLeft < 7) return Colors.orange.shade100; 
    return Colors.green.shade100;                    
  }

  Future<void> _editItem(Map<String, dynamic> item) async {
    await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => AddItemScreen(itemToEdit: item))
    );
    _fetchItems(); 
  }

  Future<void> _deleteAccount() async {
      try {
        await http.delete(Uri.parse('http://10.0.2.2:8080/auth/delete/$_currentUserId'));
        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account Deleted.")));
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
        }
      } catch (e) { print(e); }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("This will erase ALL your data permanently. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAccount();
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _selectedFilter == "All" ? _items : _items.where((item) => item['category'] == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Expiry Plans", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent, foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                 Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
              } else if (value == 'delete') {
                _showDeleteAccountDialog();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(value: 'logout', child: Text('Logout (Keep Data)')),
                const PopupMenuItem(value: 'delete', child: Text('Delete Account (Erase Data)', style: TextStyle(color: Colors.red))),
              ];
            },
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                   _buildCategoryCard(Icons.list, "All", Colors.black),
                   const SizedBox(width: 15),
                  _buildCategoryCard(Icons.fastfood, "Food", Colors.orange),
                   const SizedBox(width: 15),
                  _buildCategoryCard(Icons.medical_services, "Medicine", Colors.green),
                   const SizedBox(width: 15),
                  _buildCategoryCard(Icons.movie, "Entertainment", Colors.purple),
                   const SizedBox(width: 15),
                  _buildCategoryCard(Icons.description, "Documents", Colors.blue),
                   const SizedBox(width: 15),
                  _buildCategoryCard(Icons.brush, "Cosmetics", Colors.pink),
                   const SizedBox(width: 15),
                  _buildCategoryCard(Icons.security, "Warranty", Colors.brown),
                   const SizedBox(width: 15),
                  _buildCategoryCard(Icons.subscriptions, "Subscriptions", Colors.teal),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text("Expiring Soon ⚠️", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final item = displayList[index];
                  final cardColor = _getUrgencyColor(item['expiryDate']);

                  return Card(
                    color: cardColor, 
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Expires: ${item['expiryDate'].toString().substring(0, 10)}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editItem(item)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteItem(item['id'])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
           await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddItemScreen()));
           _fetchItems();
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryCard(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () { setState(() => _selectedFilter = label); },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _selectedFilter == label ? color.withOpacity(0.2) : Colors.white,
          border: _selectedFilter == label ? Border.all(color: color, width: 2) : null,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(children: [Icon(icon, size: 40, color: color), Text(label)]),
      ),
    );
  }
}