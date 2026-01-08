import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'notification_service.dart';

class AddItemScreen extends StatefulWidget {
  final Map<String, dynamic>? itemToEdit; 

  const AddItemScreen({super.key, this.itemToEdit});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final TextEditingController _titleController = TextEditingController();
  String _selectedCategory = "Food";
  DateTime? _selectedDate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      _isEditing = true;
      _titleController.text = widget.itemToEdit!['title'];
      _selectedCategory = widget.itemToEdit!['category'];
      try {
        _selectedDate = DateTime.parse(widget.itemToEdit!['expiryDate']);
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000), // <--- 🟢 FIX: Allow past dates (fixes edit bugs)
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveOrUpdateItem() async {
    if (_titleController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter details")));
      return;
    }

    try {
      http.Response response;

      // 🟢 FIX: Chop off the time part so Database doesn't get confused
      String cleanDate = _selectedDate!.toIso8601String().substring(0, 10);

      if (_isEditing) {
        final id = widget.itemToEdit!['id'];
        response = await http.put(
          Uri.parse('http://10.0.2.2:8080/items/update/$id'), 
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "title": _titleController.text,
            "category": _selectedCategory,
            "expiryDate": cleanDate,
          }),
        );
      } else {
        response = await http.post(
          Uri.parse('http://10.0.2.2:8080/items/add'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "title": _titleController.text,
            "category": _selectedCategory,
            "expiryDate": cleanDate,
            "userId": 1
          }),
        );
      }

      if (response.statusCode == 200) {
        // Notification
        try {
          await NotificationService.scheduleNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000, 
            title: _titleController.text, 
            expiryDate: _selectedDate!
          );
        } catch (e) {
          print("Notification Schedule Failed: $e");
        }

        if (mounted) {
           Navigator.pop(context, true); 
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${response.body}'))
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Item" : "Add New Item"), 
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Item Name", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _titleController, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 20),
            
            const Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(5)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: ["Food", "Medicine", "Entertainment", "Documents", "Cosmetics", "Warranty", "Subscriptions"]
                      .map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Expiry Date", style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              title: Text(_selectedDate == null ? "Select Date" : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"),
              trailing: const Icon(Icons.calendar_today, color: Colors.blueAccent),
              shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(5)),
              onTap: _pickDate,
            ),
            const Spacer(),

            ElevatedButton(
              onPressed: _saveOrUpdateItem,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 50)),
              child: Text(_isEditing ? "Update Item" : "Save Item", style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}