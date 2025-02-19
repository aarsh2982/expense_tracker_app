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

  Widget _buildCategoryItem(String category) {
    final bool isSelected = _selectedCategory == category;
    final color = widget.isIncome ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.8),
                    color,
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? Colors.transparent : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _categoryIcons[category] ?? Icons.more_horiz,
              color: isSelected ? Colors.white : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final color = widget.isIncome ? Colors.green : Colors.red;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: color.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      labelStyle: TextStyle(color: color.withOpacity(0.7)),
    );
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.isIncome ? "Income" : "Expense"} saved successfully',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: widget.isIncome ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving ${widget.isIncome ? "income" : "expense"}: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.isIncome ? _incomeCategories : _expenseCategories;
    final color = widget.isIncome ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text(
          widget.item == null
              ? 'Add ${widget.isIncome ? "Income" : "Expense"}'
              : 'Edit Transaction',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: color,
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
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amount',
                            style: TextStyle(
                              color: color.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: _amount > 0 ? _amount.toString() : '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              prefixStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                              border: InputBorder.none,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
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
                            },
                            onSaved: (value) =>
                                _amount = double.tryParse(value ?? '0') ?? 0.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Title',
                    style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _title,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Enter title', Icons.title),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter a title' : null,
                    onSaved: (value) => _title = value ?? '',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Category',
                    style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    children: categories.map(_buildCategoryItem).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saveItem,
                      child: Text(
                        widget.item == null
                            ? 'Add Transaction'
                            : 'Update Transaction',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
