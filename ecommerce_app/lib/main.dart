import 'package:flutter/material.dart';
import 'databaseHelper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-commerce App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CategoryListScreen(),
    );
  }
}

class CategoryListScreen extends StatelessWidget {
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Categories'),
      ),
      body: FutureBuilder(
        future: dbHelper.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final categories = snapshot.data as List<Map<String, dynamic>>;
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(categories[index]['categoryName']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductListScreen(
                        categoryId: categories[index]['id'],
                        categoryName: categories[index]['categoryName'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  ProductListScreen({required this.categoryId, required this.categoryName});

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  String searchQuery = ""; // 搜索关键字变量
  bool showFavoritesOnly = false; // 筛选最爱产品的开关变量

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products in ${widget.categoryName}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value; // 更新搜索关键字
                });
              },
              decoration: InputDecoration(
                labelText: 'Search Products',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SwitchListTile(
            title: Text('Show Favorites Only'), // 筛选最爱产品开关
            value: showFavoritesOnly,
            onChanged: (value) {
              setState(() {
                showFavoritesOnly = value; // 更新筛选状态
              });
            },
          ),
          Expanded(
            child: FutureBuilder(
              future: dbHelper.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                var products = (snapshot.data as List<Map<String, dynamic>>)
                    .where((product) => product['categoryId'] == widget.categoryId)
                    .toList();

                // 根据搜索和筛选条件过滤产品
                if (searchQuery.isNotEmpty) {
                  products = products
                      .where((product) =>
                          product['productName']
                              .toLowerCase()
                              .contains(searchQuery.toLowerCase()))
                      .toList();
                }

                if (showFavoritesOnly) {
                  products = products.where((product) => product['isFavorite'] == 1).toList();
                }

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(products[index]['productName']),
                      trailing: IconButton(
                        icon: Icon(
                          products[index]['isFavorite'] == 1
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: products[index]['isFavorite'] == 1
                              ? Colors.red
                              : null,
                        ),
                        onPressed: () {
                          dbHelper.toggleFavorite(
                              products[index]['id'], products[index]['isFavorite'] == 0);
                          setState(() {}); // 刷新页面以更新图标
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReviewListScreen(
                              productId: products[index]['id'],
                              productName: products[index]['productName'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewListScreen extends StatelessWidget {
  final int productId;
  final String productName;
  final DatabaseHelper dbHelper = DatabaseHelper();

  ReviewListScreen({required this.productId, required this.productName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews for $productName'),
      ),
      body: FutureBuilder(
        future: dbHelper.getReviews(productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final reviews = snapshot.data as List<Map<String, dynamic>>;
          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(reviews[index]['reviewText']),
                subtitle: Text('Rating: ${reviews[index]['rating']}'),
              );
            },
          );
        },
      ),
    );
  }
}
