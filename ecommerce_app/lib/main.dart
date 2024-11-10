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
      home: ProductListScreen(),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  String searchQuery = ""; // Search keyword
  bool showFavoritesOnly = false; // Toggle for showing favorites only
  String? selectedCategory; // Currently selected category
  List<Map<String, dynamic>> products = []; // List of products to display after filtering
  List<Map<String, dynamic>> categories = []; // List of available categories

  @override
  void initState() {
    super.initState();
    _loadCategories(); // Load categories on initialization
    _loadProducts(); // Load products on initialization
  }

  Future<void> _loadCategories() async {
    // Retrieve all categories from the database
    final categoryList = await dbHelper.getCategories();
    setState(() {
      categories = categoryList;
    });
  }

  Future<void> _loadProducts() async {
    List<Map<String, dynamic>> productList;
    if (selectedCategory != null) {
      // Filter products based on selected category
      productList = await dbHelper.getProductsByCategory(selectedCategory!);
    } else {
      // If no category is selected, show all products
      productList = await dbHelper.getProducts();
    }

    // Filter based on search query
    if (searchQuery.isNotEmpty) {
      productList = productList
          .where((product) => product['productName']
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList();
    }

    // Filter based on favorites
    if (showFavoritesOnly) {
      productList = productList.where((product) => product['isFavorite'] == 1).toList();
    }

    setState(() {
      products = productList;
    });
  }

  void _showProductDialog(BuildContext context, {Map<String, dynamic>? product}) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    List<Map<String, dynamic>> categories = await dbHelper.getCategories();
    int? selectedCategoryId;

    if (product != null) {
      nameController.text = product['productName'];
      priceController.text = product['price'].toString();
      selectedCategoryId = product['categoryId'];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(product == null ? 'Add Product' : 'Edit Product'),
          content: SingleChildScrollView(
            child: Column(
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
                DropdownButton<int>(
                  value: selectedCategoryId,
                  hint: Text('Select Category'),
                  isExpanded: true,
                  items: categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category['id'],
                      child: Text(category['categoryName']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategoryId = value;
                    });
                  },
                ),
              ],
            ),
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

                if (nameController.text.isEmpty || selectedCategoryId == null) {
                  _showErrorDialog(context, 'Product Name, Price, and Category are required fields.');
                  return;
                }

                final newProduct = {
                  'productName': nameController.text,
                  'price': double.parse(priceController.text),
                  'categoryId': selectedCategoryId
                };
                Navigator.pop(context);

                if (product == null) {
                  await dbHelper.insertProduct(newProduct);
                  _showConfirmationDialog(context, 'Product Added',
                      '${newProduct['productName']} has been added successfully.');
                } else {
                  await dbHelper.updateProduct(product['id'], newProduct);
                  _showConfirmationDialog(context, 'Product Updated Successfully',
                      'Updated Name: ${newProduct['productName']}\n'
                      'Updated Price: \$${newProduct['price']}');
                }

                _loadProducts(); // Update the product list
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
                _loadProducts(); // Refresh product list
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
        title: Text('All Products'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
                _loadProducts(); // Update product list
              },
              decoration: InputDecoration(
                labelText: 'Search Products',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedCategory,
              hint: Text('Select Category'),
              isExpanded: true,
              items: [
                DropdownMenuItem<String>(
                  value: null, // Set to null to represent selecting all categories
                  child: Text('All Products'), // Display text
                ),
                ...categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['categoryName'],
                    child: Text(category['categoryName']),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
                _loadProducts(); // Update product list
              },
            ),
          ),
          SwitchListTile(
            title: Text('Show Favorites Only'),
            value: showFavoritesOnly,
            onChanged: (value) {
              setState(() {
                showFavoritesOnly = value;
              });
              _loadProducts(); // Update product list
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(products[index]['productName']),
                  subtitle: Text('\$${products[index]['price']}'),
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
                                      Navigator.pop(context, false);
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },
                                    child: Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirmDelete == true) {
                            await dbHelper.deleteProduct(products[index]['id']);
                            _loadProducts(); // Update product list
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          products[index]['isFavorite'] == 1
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: products[index]['isFavorite'] == 1 ? Colors.red : null,
                        ),
                        onPressed: () {
                          dbHelper.toggleFavorite(products[index]['id'], products[index]['isFavorite'] == 0);
                          _loadProducts(); // Update product list
                        },
                      ),
                    ],
                  ),
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