import 'package:flutter/material.dart';
import '../controllers/task_controller.dart';
import '../services/finnhub_service.dart';
import 'sell_stock_page.dart';

class Page1 extends StatefulWidget {
  final String userId;
  const Page1({Key? key, required this.userId}) : super(key: key);

  @override
  _Page1State createState() => _Page1State();
}

class _Page1State extends State<Page1> {
  final finnhubService = FinnhubService();
  double? totalMoney;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: TaskController().getUserData(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
          return Center(child: Text('User not found'));
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final stocksBought = userData['stocks_bought'] ?? [];

        Future<double> calculateTotalMoney() async {
          double totalStockValue = 0.0;
          for (var stock in stocksBought) {
            final stockData = await finnhubService.getStockQuote(stock['name']);
            final stockPrice = stockData['c']; // Current price
            int shares = (stock['shares_bought'] is int)
                ? stock['shares_bought']
                : int.tryParse(stock['shares_bought'].toString()) ?? 0;
            totalStockValue += stockPrice * shares;
          }
          return totalStockValue + (userData['unused_money'] ?? 0);
        }

        return FutureBuilder<double>(
          future: calculateTotalMoney(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              totalMoney = snapshot.data;
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Total Money: ${totalMoney?.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        double newTotalMoney = await calculateTotalMoney();
                        setState(() {
                          totalMoney = newTotalMoney;
                        });
                        await Future.delayed(Duration(seconds: 10));
                      },
                      child: ListView.builder(
                        itemCount: stocksBought.where((stock) => (stock['shares_bought'] as int) > 0).length,
                        itemBuilder: (context, index) {
                          final stock = stocksBought.where((stock) => (stock['shares_bought'] as int) > 0).toList()[index];
                          return GestureDetector(
                            onTap: () async {
                              final stockName = stock['name'] as String?;
                              if (stockName != null) {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SellStockPage(
                                      userId: widget.userId,
                                      stockName: stockName,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  setState(() {});
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Stock name not found')),
                                );
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(12.0),
                                color: Colors.white,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      stock['name'],
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    Text(
                                      'Shares: ${(stock['shares_bought'] is int) ? stock['shares_bought'].toString() : int.tryParse(stock['shares_bought'].toString())?.toString() ?? '?'}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }
}
