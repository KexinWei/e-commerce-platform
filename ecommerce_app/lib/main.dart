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

class ProductListScreen extends StatelessWidget {
  final int categoryId;
  final String categoryName;
  final DatabaseHelper dbHelper = DatabaseHelper();

  ProductListScreen({required this.categoryId, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products in $categoryName'),
      ),
      body: FutureBuilder(
        future: dbHelper.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final products = (snapshot.data as List<Map<String, dynamic>>)
              .where((product) => product['categoryId'] == categoryId)
              .toList();
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
