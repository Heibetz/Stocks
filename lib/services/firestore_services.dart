import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final db = FirebaseFirestore.instance;

  // Add a new stock to user's stocks
  Future<void> addStock(String userId, String stockName, int sharesBought) {
    return db.collection('users').doc(userId).update({
      'stocks_bought': FieldValue.arrayUnion([{
        'name': stockName,
        'shares_bought': sharesBought,
      }]),
    });
  }

  // Update user's unused money
  Future<void> updateUnusedMoney(String userId, double unusedMoney) {
    return db.collection('users').doc(userId).update({
      'unused_money': unusedMoney,
    });
  }

  // Update user's stocks and unused money
  Future<void> updateUserStocksAndMoney(String userId, List stocksBought, double unusedMoney) {
    return db.collection('users').doc(userId).update({
      'stocks_bought': stocksBought,
      'unused_money': unusedMoney,
    });
  }

  // Get user's stocks and unused money
  Future<DocumentSnapshot> getUserData(String userId) {
    return db.collection('users').doc(userId).get();
  }

  // Update a stock
  Future<void> updateStock(String userId, String stockId, int quantity) {
    return db.collection('users').doc(userId).collection('stocks').doc(stockId).update({
      'quantity': quantity,
    });
  }
}