import 'package:flutter/material.dart';
import '../controllers/task_controller.dart';

class BuyStocksPage extends StatefulWidget {
  final String symbol;
  final String currentPrice;
  final String userId;

  const BuyStocksPage({Key? key, required this.symbol, required this.currentPrice, required this.userId}) : super(key: key);

  @override
  _BuyStocksPageState createState() => _BuyStocksPageState();
}

class _BuyStocksPageState extends State<BuyStocksPage> {
  final TextEditingController _sharesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buy ${widget.symbol}'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Current Price: \$${widget.currentPrice}'),
            SizedBox(height: 20),
            TextField(
              controller: _sharesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Number of Shares',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Cancel action
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final userId = widget.userId;
                    final sharesText = _sharesController.text.trim();
                    int? sharesToBuy = int.tryParse(sharesText);
                    if (sharesToBuy == null || sharesToBuy <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a valid number of shares.')),
                      );
                      return;
                    }
                    final doc = await TaskController().getUserData(userId);
                    final userData = doc.data() as Map<String, dynamic>;
                    double unusedMoney = (userData['unused_money'] ?? 0).toDouble();
                    final double stockPrice = double.tryParse(widget.currentPrice) ?? 0;
                    final double totalCost = stockPrice * sharesToBuy;
                    if (totalCost > unusedMoney) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Insufficient funds to complete this purchase.')),
                      );
                      return;
                    }
                    // Find if the user already owns this stock
                    List stocksBought = List.from(userData['stocks_bought'] ?? []);
                    bool stockExists = false;
                    for (var stock in stocksBought) {
                      if (stock['name'] == widget.symbol) {
                        stock['shares_bought'] = (int.tryParse(stock['shares_bought'].toString()) ?? 0) + sharesToBuy;
                        stockExists = true;
                        break;
                      }
                    }
                    if (!stockExists) {
                      stocksBought.add({'name': widget.symbol, 'shares_bought': sharesToBuy});
                    }
                    double newUnusedMoney = unusedMoney - totalCost;
                    TaskController().updateUserStocksAndMoney(userId, stocksBought, newUnusedMoney);
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Buy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}