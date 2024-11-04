
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ecommerce.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Category (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryName TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE Product (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productName TEXT NOT NULL,
        categoryId INTEGER,
        isFavorite INTEGER DEFAULT 0,
        FOREIGN KEY (categoryId) REFERENCES Category(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE Review (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER,
        reviewText TEXT,
        rating INTEGER,
        FOREIGN KEY (productId) REFERENCES Product(id)
      );
    ''');

    // Create indexes to improve search speed
    await db.execute('CREATE INDEX idx_product_name ON Product(productName);');
    await db.execute('CREATE INDEX idx_category_name ON Category(categoryName);');

    // Insert dummy data
    await _insertDummyData(db);
  }

  // CRUD operations for Category
  Future<int> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert('Category', category);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('Category');
  }

  // CRUD operations for Product
  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.insert('Product', product);
  }

  Future<List<Map<String, dynamic>>> getProducts({String? query}) async {
    final db = await database;
    if (query != null && query.isNotEmpty) {
      return await db.query('Product',
          where: 'productName LIKE ?', whereArgs: ['%$query%']);
    }
    return await db.query('Product');
  }

  Future<int> updateProduct(int id, Map<String, dynamic> product) async {
    final db = await database;
    return await db.update('Product', product, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('Product', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD operations for Review
  Future<int> insertReview(Map<String, dynamic> review) async {
    final db = await database;
    return await db.insert('Review', review);
  }

  Future<List<Map<String, dynamic>>> getReviews(int productId) async {
    final db = await database;
    return await db.query('Review', where: 'productId = ?', whereArgs: [productId]);
  }

  // Favorites functionality
  Future<int> toggleFavorite(int productId, bool isFavorite) async {
    final db = await database;
    return await db.update('Product', {'isFavorite': isFavorite ? 1 : 0},
        where: 'id = ?', whereArgs: [productId]);
  }

  Future<List<Map<String, dynamic>>> getFavoriteProducts() async {
    final db = await database;
    return await db.query('Product', where: 'isFavorite = ?', whereArgs: [1]);
  }

  Future<void> _insertDummyData(Database db) async {
    // Insert categories
    int electronicsId = await db.insert('Category', {'categoryName': 'Electronics'});
    int clothingId = await db.insert('Category', {'categoryName': 'Clothing'});

    // Insert products
    await db.insert('Product', {'productName': 'Laptop', 'categoryId': electronicsId, 'isFavorite': 1});
    await db.insert('Product', {'productName': 'Smartphone', 'categoryId': electronicsId});
    await db.insert('Product', {'productName': 'T-Shirt', 'categoryId': clothingId});
    await db.insert('Product', {'productName': 'Jeans', 'categoryId': clothingId, 'isFavorite': 1});

    // Insert reviews for products
    await db.insert('Review', {'productId': 1, 'reviewText': 'Great performance!', 'rating': 5});
    await db.insert('Review', {'productId': 1, 'reviewText': 'Good value for the price', 'rating': 4});
    await db.insert('Review', {'productId': 2, 'reviewText': 'Battery life could be better', 'rating': 3});
  }
}
