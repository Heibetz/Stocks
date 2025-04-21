import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'finnhub_service.dart';

const String _apiKey = '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';

class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();

  factory OpenAIService() => _instance;

  final requestMessages = <OpenAIChatCompletionChoiceMessageModel>[];

  OpenAIService._internal() {
    OpenAI.apiKey = _apiKey;

    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "You are a financial advisor AI. You have access to the user's purchased stocks and their remaining balance. You can change the user's balance and stocks in the database. Engage the user in a conversation about their current stock portfolio and suggest potential stocks to buy based on market trends. Provide insights and advice on stock trading, and make the conversation engaging and informative.")
      ],
      role: OpenAIChatMessageRole.system,
    );

    requestMessages.add(systemMessage);
  }

  Future<String?> chat(String userMessage, String userId) async {
    _addMessage(isFromUser: true, message: userMessage);

    await handleUserIntent(userMessage, userId);

    OpenAIChatCompletionModel chatCompletion =
        await OpenAI.instance.chat.create(
      model: "gpt-4o-mini",
      seed: 6,
      messages: requestMessages,
      temperature: 0.2,
      maxTokens: 500,
    );
    final text = chatCompletion.choices.last.message.content?.first.text;

    if (text == null) {
      if (kDebugMode) {
        print('Something went wrong');
      }
    } else {
      _addMessage(isFromUser: false, message: text);

      if (kDebugMode) {
        print('${chatCompletion.usage.promptTokens}\t$text');
      }
    }

    return text;
  }

  void _addMessage({required String message, required bool isFromUser}) {
    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(message),
      ],
      role: isFromUser
          ? OpenAIChatMessageRole.user
          : OpenAIChatMessageRole.assistant,
    );
    requestMessages.add(userMessage);
  }

  Future<void> fetchPortfolioData(String userId) async {
    try {
      // Fetch the user's portfolio data from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final stocksBought = userData['stocks_bought'] ?? [];
        final unusedMoney = userData['unused_money'] ?? 0.0;

        // Update the AI's system message or context with the portfolio data
        final updatedSystemMessage = OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
                "You are a financial advisor AI. The user has the following stocks: " +
                stocksBought.map((stock) => "${stock['name']} (${stock['shares_bought']} shares)").join(", ") +
                ". They have \$${unusedMoney.toStringAsFixed(2)} left. " +
                "You have access to the user's purchased stocks and their remaining balance." + 
                "You can change the user's balance and stocks in the database. " + 
                "Engage the user in a conversation about their current stock portfolio and suggest potential stocks to buy based on market trends." + 
                "Provide insights and advice on stock trading, and make the conversation engaging and informative.")
          ],
          role: OpenAIChatMessageRole.system,
        );
        requestMessages.insert(0, updatedSystemMessage);
      } else {
        // Handle the case where the user document does not exist
        _addMessage(message: "User data not found.", isFromUser: false);
      }
    } catch (e) {
      // Handle any errors that occur during the fetch
      _addMessage(message: "Error fetching portfolio data: \$e", isFromUser: false);
    }
  }

  Future<void> handleUserIntent(String message, String userId) async {
    final buyPattern = RegExp(r"buy (\d+) stocks of (\w+)", caseSensitive: false);
    final sellPattern = RegExp(r"sell (\d+) stocks of (\w+)", caseSensitive: false);

    final buyMatch = buyPattern.firstMatch(message);
    final sellMatch = sellPattern.firstMatch(message);

    if (buyMatch != null) {
      final quantity = int.parse(buyMatch.group(1)!);
      final stockName = buyMatch.group(2)!;
      await _buyStock(userId, stockName, quantity);
    } else if (sellMatch != null) {
      final quantity = int.parse(sellMatch.group(1)!);
      final stockName = sellMatch.group(2)!;
      await _sellStock(userId, stockName, quantity);
    }
  }

  Future<void> _buyStock(String userId, String stockName, int quantity) async {
    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userDocRef);

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final stocksBought = List<Map<String, dynamic>>.from(userData['stocks_bought'] ?? []);
          final unusedMoney = userData['unused_money'] ?? 0.0;

          // Fetch stock price using FinnhubService
          final stockData = await FinnhubService().getStockQuote(stockName);
          final stockPrice = stockData['c']; // Current price
          final totalCost = stockPrice * quantity;

          if (unusedMoney >= totalCost) {
            // Find the stock in the user's portfolio
            final stockIndex = stocksBought.indexWhere((stock) => stock['name'] == stockName);
            if (stockIndex != -1) {
              // Update the number of shares if the stock already exists
              stocksBought[stockIndex]['shares_bought'] += quantity;
            } else {
              // Add the new stock to the portfolio
              stocksBought.add({'name': stockName, 'shares_bought': quantity});
            }

            // Update Firestore with new stock data and balance
            transaction.update(userDocRef, {
              'stocks_bought': stocksBought,
              'unused_money': unusedMoney - totalCost
            });
            _addMessage(message: "Bought ${quantity.toString()} stocks of ${stockName} at \$$stockPrice each. Total cost: \$$totalCost.", isFromUser: false);
          } else {
            _addMessage(message: "Insufficient funds to buy ${quantity.toString()} stocks of ${stockName}.", isFromUser: false);
          }
        } else {
          _addMessage(message: "User data not found.", isFromUser: false);
        }
      });
    } catch (e) {
      _addMessage(message: "Error buying stocks: $e", isFromUser: false);
    }
  }

  Future<void> _sellStock(String userId, String stockName, int quantity) async {
    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userDocRef);

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final stocksBought = List<Map<String, dynamic>>.from(userData['stocks_bought'] ?? []);
          final unusedMoney = userData['unused_money'] ?? 0.0;

          // Fetch stock price using FinnhubService
          final stockData = await FinnhubService().getStockQuote(stockName);
          final stockPrice = stockData['c']; // Current price
          final totalRevenue = stockPrice * quantity;

          // Find the stock in the user's portfolio
          final stockIndex = stocksBought.indexWhere((stock) => stock['name'] == stockName);
          if (stockIndex != -1) {
            // Update the number of shares if the stock exists
            final currentShares = stocksBought[stockIndex]['shares_bought'];
            if (currentShares >= quantity) {
              stocksBought[stockIndex]['shares_bought'] -= quantity;
              if (stocksBought[stockIndex]['shares_bought'] == 0) {
                stocksBought.removeAt(stockIndex); // Remove stock if no shares left
              }
              // Update Firestore with new stock data and balance
              transaction.update(userDocRef, {
                'stocks_bought': stocksBought,
                'unused_money': unusedMoney + totalRevenue
              });
              _addMessage(message: "Sold ${quantity.toString()} stocks of ${stockName} at \$$stockPrice each. Total revenue: \$$totalRevenue.", isFromUser: false);
            } else {
              _addMessage(message: "Not enough shares to sell.", isFromUser: false);
            }
          } else {
            _addMessage(message: "Stock not found in portfolio.", isFromUser: false);
          }
        } else {
          _addMessage(message: "User data not found.", isFromUser: false);
        }
      });
    } catch (e) {
      _addMessage(message: "Error selling stocks: $e", isFromUser: false);
    }
  }
}