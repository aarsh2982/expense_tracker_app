import 'package:flutter/material.dart';
import 'package:expense_tracker_app/database_helper.dart';
import 'package:expense_tracker_app/models/item_model.dart';
import 'dart:ui';

class AddEditScreen extends StatefulWidget {
  final Item? item;
  final String category;
  final bool isIncome;

  const AddEditScreen(
      {Key? key, this.item, required this.category, required this.isIncome})
      : super(key: key);

  @override
  _AddEditScreenState createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _selectedCategory;
  late double _amount;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Separate categories for income and expense
  final List<String> _expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Others'
  ];

  final List<String> _incomeCategories = [
    'Salary',
    'Freelancing',
    'Business',
    'Investment',
    'Others'
  ];

  final Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Bills': Icons.receipt_long,
    'Entertainment': Icons.movie,
    'Salary': Icons.work,
    'Freelancing': Icons.computer,
    'Business': Icons.business,
    'Investment': Icons.trending_up,
    'Others': Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();

    // Initialize with existing data or defaults
    _title = widget.item?.title ?? '';
    _amount = widget.item?.amount ?? 0.0;
    _selectedCategory = widget.item?.category ?? widget.category;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final newItem = Item(
          id: widget.item?.id,
          title: _title,
          amount: _amount,
          type: widget.isIncome ? 'income' : 'expense',
          category: _selectedCategory,
        );

        if (widget.item == null) {
          await _dbHelper.insertItem(newItem);
        } else {
          await _dbHelper.updateItem(newItem);
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${widget.isIncome ? "Income" : "Expense"} saved successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Pop twice if showing category selection
        Navigator.pop(context);
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error saving ${widget.isIncome ? "income" : "expense"}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    if (double.parse(value) <= 0) {
      return 'Amount must be greater than 0';
    }
    return null;
  }

  Widget _buildCategoryIcon(String category) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _categoryIcons[category] ?? Icons.more_horiz,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.white70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.isIncome ? _incomeCategories : _expenseCategories;

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text(
          widget.item == null
              ? 'Add ${widget.isIncome ? "Income" : "Expense"}'
              : 'Edit Transaction',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: widget.isIncome ? Colors.green : Colors.redAccent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Input
                  TextFormField(
                    initialValue: _title,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Title', Icons.title),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter a title' : null,
                    onSaved: (value) => _title = value ?? '',
                  ),
                  const SizedBox(height: 20),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    dropdownColor: Colors.blueGrey[800],
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Category',
                      _categoryIcons[_selectedCategory] ?? Icons.category,
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            _buildCategoryIcon(category),
                            const SizedBox(width: 12),
                            Text(category,
                                style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Amount Input
                  TextFormField(
                    initialValue: _amount > 0 ? _amount.toString() : '',
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Amount', Icons.money),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: _validateAmount,
                    onSaved: (value) =>
                        _amount = double.tryParse(value ?? '0') ?? 0.0,
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            widget.isIncome ? Colors.green : Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saveItem,
                      child: Text(
                        widget.item == null
                            ? 'Add ${widget.isIncome ? "Income" : "Expense"}'
                            : 'Update Transaction',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
