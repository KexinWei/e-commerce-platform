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

  void _showProductDialog(BuildContext context, {Map<String, dynamic>? product}) {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  if (product != null) {
    nameController.text = product['productName'];
    priceController.text = product['price'].toString();
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(product == null ? 'Add Product' : 'Edit Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Product Name'),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Price'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {

              double? price = double.tryParse(priceController.text);
              if (price == null || price <= 0) {
                _showErrorDialog(context, 'Price must be a valid positive number.');
                return;
              }

              if (nameController.text.isEmpty || priceController.text.isEmpty) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Error'),
                    content: Text('Product Name and Price are required fields.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }
              
              final newProduct = {
                'productName': nameController.text,
                'price': double.parse(priceController.text),
                'categoryId': widget.categoryId,
              };
              Navigator.pop(context);

              if (product == null) {
                await dbHelper.insertProduct(newProduct);
                _showConfirmationDialog(context, 'Product Added',
                    '${newProduct['productName']} has been added successfully.');
              } else {
                // Update existing product
                await dbHelper.updateProduct(product['id'], newProduct);
                _showConfirmationDialog(context, 'Product Updated Successfully',
                    'Updated Name: ${newProduct['productName']}\n'
                    'Updated Price: \$${newProduct['price']}');
              }

              setState(() {}); // Refresh the list of products
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}

void _showConfirmationDialog(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              setState(() {});
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}
void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}


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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _showProductDialog(context, product: products[index]);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              bool? confirmDelete = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Confirm Deletion'),
                                    content: Text('Are you sure you want to delete ${products[index]['productName']}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, false); // No
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, true); // Yes
                                        },
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (confirmDelete == true) {
                                await dbHelper.deleteProduct(products[index]['id']);
                                setState(() {});
                              }
                            },
                          ),
                          IconButton(
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
                        ],
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
      floatingActionButton: FloatingActionButton(
      onPressed: () {
        _showProductDialog(context);
      },
      child: Icon(Icons.add),
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
