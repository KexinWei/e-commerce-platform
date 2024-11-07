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
        price REAL,  -- 价格字段
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

    // 建立索引来优化查询性能
    await db.execute('CREATE INDEX idx_product_name ON Product(productName);');
    await db.execute('CREATE INDEX idx_category_name ON Category(categoryName);');

    // 插入初始数据
    await _insertDummyData(db);
  }

  // 插入测试数据
  Future<void> _insertDummyData(Database db) async {
    int electronicsId = await db.insert('Category', {'categoryName': 'Electronics'});
    int clothingId = await db.insert('Category', {'categoryName': 'Clothing'});

    await db.insert('Product', {'productName': 'Laptop', 'categoryId': electronicsId, 'price': 999.99, 'isFavorite': 1});
    await db.insert('Product', {'productName': 'Smartphone', 'categoryId': electronicsId, 'price': 499.99});
    await db.insert('Product', {'productName': 'T-Shirt', 'categoryId': clothingId, 'price': 19.99});
    await db.insert('Product', {'productName': 'Jeans', 'categoryId': clothingId, 'price': 49.99, 'isFavorite': 1});

    await db.insert('Review', {'productId': 1, 'reviewText': 'Great performance!', 'rating': 5});
    await db.insert('Review', {'productId': 1, 'reviewText': 'Good value for the price', 'rating': 4});
    await db.insert('Review', {'productId': 2, 'reviewText': 'Battery life could be better', 'rating': 3});
  }

  // CRUD 操作 - Category
  Future<int> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert('Category', category);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('Category');
  }

  // CRUD 操作 - Product
  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.insert('Product', product);
  }

  Future<List<Map<String, dynamic>>> getProducts({
    String? query,
    int? categoryId,
    bool? isFavorite,
    int? minRating,
    double? minPrice,
    double? maxPrice,
  }) async {
    final db = await database;
    
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];
    
    if (query != null && query.isNotEmpty) {
      whereClauses.add('productName LIKE ?');
      whereArgs.add('%$query%');
    }
    
    if (categoryId != null) {
      whereClauses.add('categoryId = ?');
      whereArgs.add(categoryId);
    }
    
    if (isFavorite != null) {
      whereClauses.add('isFavorite = ?');
      whereArgs.add(isFavorite ? 1 : 0);
    }

    if (minRating != null) {
      whereClauses.add('(SELECT AVG(rating) FROM Review WHERE Review.productId = Product.id) >= ?');
      whereArgs.add(minRating);
    }

    if (minPrice != null) {
      whereClauses.add('price >= ?');
      whereArgs.add(minPrice);
    }

    if (maxPrice != null) {
      whereClauses.add('price <= ?');
      whereArgs.add(maxPrice);
    }
    
    String? whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    
    return await db.query('Product', where: whereString, whereArgs: whereArgs);
  }

  Future<int> updateProduct(int id, Map<String, dynamic> product) async {
    final db = await database;
    return await db.update('Product', product, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('Product', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD 操作 - Review
  Future<int> insertReview(Map<String, dynamic> review) async {
    final db = await database;
    return await db.insert('Review', review);
  }

  Future<List<Map<String, dynamic>>> getReviews(int productId) async {
    final db = await database;
    return await db.query('Review', where: 'productId = ?', whereArgs: [productId]);
  }

  // 收藏功能
  Future<int> toggleFavorite(int productId, bool isFavorite) async {
    final db = await database;
    return await db.update('Product', {'isFavorite': isFavorite ? 1 : 0},
        where: 'id = ?', whereArgs: [productId]);
  }

  Future<List<Map<String, dynamic>>> getFavoriteProducts() async {
    final db = await database;
    return await db.query('Product', where: 'isFavorite = ?', whereArgs: [1]);
  }
}
