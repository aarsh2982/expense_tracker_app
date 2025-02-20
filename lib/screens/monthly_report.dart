import 'package:flutter/material.dart';
import 'package:expense_tracker_app/database_helper.dart';
import 'package:expense_tracker_app/models/item_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({Key? key}) : super(key: key);

  @override
  _MonthlyReportScreenState createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, List<Item>> _monthlyTransactions = {};
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMonthlyData();
  }

  Future<void> _loadMonthlyData() async {
    setState(() => _isLoading = true);
    List<Item> allItems = await _dbHelper.getItems();

    // Group items by month
    Map<String, List<Item>> grouped = {};
    for (var item in allItems) {
      String monthYear = DateFormat('MMMM yyyy').format(item.dateTime);
      if (!grouped.containsKey(monthYear)) {
        grouped[monthYear] = [];
      }
      grouped[monthYear]!.add(item);
    }

    setState(() {
      _monthlyTransactions = grouped;
      _isLoading = false;
    });
  }

  Future<void> _generatePdf(String month, List<Item> transactions) async {
    final pdf = pw.Document();

    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );

    double totalIncome = transactions
        .where((item) => item.type == 'income')
        .fold(0, (sum, item) => sum + item.amount);

    double totalExpense = transactions
        .where((item) => item.type == 'expense')
        .fold(0, (sum, item) => sum + item.amount);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Text('Monthly Report - $month',
                style: pw.TextStyle(fontSize: 24, font: font)),
            pw.SizedBox(height: 16),
            pw.Text('Total Income: ₹${totalIncome.toStringAsFixed(2)}',
                style: pw.TextStyle(font: font, color: PdfColors.green)),
            pw.Text('Total Expense: ₹${totalExpense.toStringAsFixed(2)}',
                style: pw.TextStyle(font: font, color: PdfColors.red)),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(transaction.title,
                          style: pw.TextStyle(font: font)),
                      pw.Text('₹${transaction.amount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                              font: font,
                              color: transaction.type == 'income'
                                  ? PdfColors.green
                                  : PdfColors.red)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'Monthly_Report_$month.pdf');
  }

  Widget _buildMonthlyCard(String month, List<Item> transactions) {
    double totalIncome = transactions
        .where((item) => item.type == 'income')
        .fold(0, (sum, item) => sum + item.amount);

    double totalExpense = transactions
        .where((item) => item.type == 'expense')
        .fold(0, (sum, item) => sum + item.amount);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          month,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Balance: ₹${(totalIncome - totalExpense).toStringAsFixed(2)}',
          style: TextStyle(
            color: totalIncome - totalExpense >= 0 ? Colors.green : Colors.red,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow('Income', totalIncome, Colors.green),
                const SizedBox(height: 8),
                _buildSummaryRow('Expense', totalExpense, Colors.red),
                const Divider(height: 24),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return ListTile(
                      leading: Icon(
                        transaction.type == 'income'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: transaction.type == 'income'
                            ? Colors.green
                            : Colors.red,
                      ),
                      title: Text(transaction.title),
                      subtitle: Text(transaction.category),
                      trailing: Text(
                        '₹${transaction.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: transaction.type == 'income'
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _generatePdf(month, transactions),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export to PDF'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monthly Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _monthlyTransactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color:
                            Theme.of(context).iconTheme.color?.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions found!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color
                                  ?.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _monthlyTransactions.length,
                  itemBuilder: (context, index) {
                    String month = _monthlyTransactions.keys.elementAt(index);
                    return _buildMonthlyCard(
                      month,
                      _monthlyTransactions[month]!,
                    );
                  },
                ),
    );
  }
}
