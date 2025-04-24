import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/finnhub_service.dart';
import 'buy_stocks_page.dart';
import '../controllers/task_controller.dart';

class BuySellPage extends StatefulWidget {
  final String userId;
  const BuySellPage({Key? key, required this.userId}) : super(key: key);

  @override
  _BuySellPageState createState() => _BuySellPageState();
}

class _BuySellPageState extends State<BuySellPage> {
  final finnhubService = FinnhubService();
  final List<String> featuredStocks = ['AAPL', 'TSLA', 'AMD', 'GOOGL', 'MSFT'];
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _searchedStock;

  Future<void> _searchStock() async {
    final stockName = _searchController.text.trim();
    if (stockName.isNotEmpty) {
      final stockData = await finnhubService.getStockQuote(stockName);
      setState(() {
        _searchedStock = stockData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Stock',
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: _searchStock,
              ),
            ),
          ),
        ),
        if (_searchedStock != null)
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BuyStocksPage(
                    userId: widget.userId,
                    symbol: _searchController.text.trim(),
                    currentPrice: _searchedStock?['c']?.toStringAsFixed(2) ?? 'N/A',
                  ),
                ),
              );
              if (result == true) {
                setState(() {
                  _searchedStock = null;
                });
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
                      _searchController.text.trim(),
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Price: ${_searchedStock?['c']?.toStringAsFixed(2) ?? 'N/A'}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: FutureBuilder(
            future: Future.wait([
              TaskController().getUserData(widget.userId),
              Future.wait(featuredStocks.map((symbol) => finnhubService.getStockQuote(symbol))),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || !(snapshot.data?[0] as DocumentSnapshot).exists) {
                return Center(child: Text('User not found'));
              }

              final userData = (snapshot.data?[0] as DocumentSnapshot).data() as Map<String, dynamic>? ?? {};
              final unusedMoney = userData['unused_money'] ?? 0.0;
              final stockData = snapshot.data?[1] as List<Map<String, dynamic>>;

              return Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Unused Money: \$${unusedMoney.toStringAsFixed(2)}'),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: featuredStocks.length,
                      itemBuilder: (context, index) {
                        final stock = stockData[index];
                        final symbol = featuredStocks[index];
                        final formattedPrice = stock['c'].toStringAsFixed(2);
                        return GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BuyStocksPage(
                                  userId: widget.userId,
                                  symbol: symbol,
                                  currentPrice: formattedPrice,
                                ),
                              ),
                            );
                            if (result == true) {
                              setState(() {});
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
                                    symbol,
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    'Price: \$$formattedPrice',
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
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
