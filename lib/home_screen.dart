import 'package:flutter/material.dart';
import 'products/brands_list_screen.dart';
import 'orders/orders_screen.dart';
import 'shops/shops_list_screen.dart';

class HomeScreen extends StatefulWidget {

  final int initialIndex;

  const HomeScreen({
    Key? key,
    this.initialIndex = 2,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }
  final List<Widget> _pages = [
    OrdersScreen(),
    BrandsListScreen(),
    ShopsListScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return "Orders";
      case 1:
        return "Products";
      case 2:
        return "Shops";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1565C0);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,

        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,

        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Shops',
          ),
        ],
      ),
    );
  }
}