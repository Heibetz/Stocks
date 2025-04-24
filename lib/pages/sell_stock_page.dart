import 'package:flutter/material.dart';
import '../services/finnhub_service.dart';
import '../controllers/task_controller.dart';

class SellStockPage extends StatefulWidget {
  final String userId;
  final String stockName;

  SellStockPage({required this.userId, required this.stockName});

  @override
  _SellStockPageState createState() => _SellStockPageState();
}

class _SellStockPageState extends State<SellStockPage> {
  late Future<Map<String, dynamic>> stockData;
  late Future<int> sharesOwned;
  final TextEditingController _sharesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final finnhubService = FinnhubService();
    stockData = finnhubService.getStockQuote(widget.stockName);
    sharesOwned = TaskController().getUserData(widget.userId).then((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>;
      final stock = data['stocks_bought']?.firstWhere(
        (s) => s['name'] == widget.stockName,
        orElse: () => {'shares_bought': 0},
      );
      return stock['shares_bought'] ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sell Stock'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock: ${widget.stockName}', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            FutureBuilder<Map<String, dynamic>>(
              future: stockData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error fetching stock data');
                } else {
                  final price = snapshot.data?['c'] ?? 0.0;
                  return Text('Current Price: \$${price.toStringAsFixed(2)}');
                }
              },
            ),
            SizedBox(height: 20),
            FutureBuilder<int>(
              future: sharesOwned,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error fetching shares owned');
                } else {
                  return Text('Shares Owned: ${snapshot.data}');
                }
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: _sharesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Number of Shares to Sell',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            SizedBox(height: 20),
            FutureBuilder<Map<String, dynamic>>(
              future: stockData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error fetching stock data');
                } else {
                  final price = snapshot.data?['c'] ?? 0.0;
                  final sharesToSell = int.tryParse(_sharesController.text) ?? 0;
                  final totalValue = price * sharesToSell;
                  return Text('Total Value: \$${totalValue.toStringAsFixed(2)}');
                }
              },
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final sharesToSell = int.tryParse(_sharesController.text);
                    if (sharesToSell == null || sharesToSell <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please input a valid number of shares.')),
                      );
                      return;
                    }

                    final currentShares = await sharesOwned;
                    if (sharesToSell > currentShares) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('You cannot sell more shares than you own.')),
                      );
                      return;
                    }

                    final stockDataMap = await stockData;
                    final pricePerShare = stockDataMap['c'] ?? 0.0;
                    final totalValue = pricePerShare * sharesToSell;

                    final userDataSnapshot = await TaskController().getUserData(widget.userId);
                    final userData = userDataSnapshot.data() as Map<String, dynamic>;
                    final stocksBought = userData['stocks_bought'] ?? [];
                    final updatedStocks = stocksBought.map((stock) {
                      if (stock['name'] == widget.stockName) {
                        stock['shares_bought'] -= sharesToSell;
                      }
                      return stock;
                    }).toList();

                    final newUnusedMoney = (userData['unused_money'] ?? 0) + totalValue;

                    await TaskController().updateUserStocksAndMoney(widget.userId, updatedStocks, newUnusedMoney);

                    Navigator.of(context).pop(true);
                  },
                  child: Text('Sell'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}