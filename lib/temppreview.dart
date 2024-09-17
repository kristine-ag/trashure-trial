import 'package:flutter/material.dart';
import 'package:trashure/components/appbar.dart';

class BookingPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> selectedItems;
  final String address;

  const BookingPreviewScreen({
    Key? key,
    required this.selectedItems,
    required this.address,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate the total weight and total price of the selected items
    double totalWeight = selectedItems.entries.fold(0, (previousValue, element) {
      // Use null-aware operators to safely handle null values
      double itemWeight = (element.value['quantity'] ?? 0) * 1.0; // If quantity is null, treat it as 0
      return previousValue + itemWeight;
    });

    double totalPrice = selectedItems.entries.fold(0, (previousValue, element) {
      double itemPrice = (element.value['quantity'] ?? 0) * (element.value['price_per_kg'] ?? 0); // Handle null price
      return previousValue + itemPrice;
    });

    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            Center(child: Column(
              children: [
                  Text(
                    'BOOKING PREVIEW',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 4,
                    width: 100,
                    color: Colors.green[700],
                  ),
                ],
            ));
            if (constraints.maxWidth > 800) {
              // For larger screens, display the cards in a Row (side by side)
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected Items takes 60% of the screen
                  Flexible(
                    flex: 6,
                    child: _buildSelectedItemsWithPrices(),
                  ),
                  const SizedBox(width: 20), // Add spacing between the cards
                  
                  // Address Card takes 40% of the screen
                  Flexible(
                    flex: 4,
                    child: _buildAddressCard(context),
                  ),
                ],
              );
              
            } else {
              // For smaller screens, stack them vertically
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSelectedItemsWithPrices(),
                  const SizedBox(height: 30),
                  _buildAddressCard(context),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  // Widget to display address details
  Widget _buildAddressCard(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Default Address',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              address.split(', Landmark: ')[0],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'House no., Landmark, etc.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Text(
              address.split(', Landmark: ').length > 1
                  ? address.split(', Landmark: ')[1]
                  : 'N/A', // Display landmark if available
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to display selected items along with their quantities, prices, and total price per item
  Widget _buildSelectedItemsWithPrices() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...selectedItems.entries.map((entry) {
              double itemQuantity = entry.value['quantity'] ?? 0; // Handle null quantity
              double pricePerKg = entry.value['price_per_kg'] ?? 0; // Handle null price
              double totalPriceForItem = itemQuantity * pricePerKg;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Polyethylene Terephthalate', // Replace with real description if needed
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${itemQuantity} kg/s',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          '₱${pricePerKg.toStringAsFixed(2)}/kg',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Total: ₱${totalPriceForItem.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
