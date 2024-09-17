class BookingInfo {
  final String serviceType;
  final String scheduleDate;
  final String additionalNotes;
  final String address;
  final String landmark;

  BookingInfo({
    required this.serviceType,
    required this.scheduleDate,
    required this.additionalNotes,
    required this.address,
    required this.landmark,
  });
}

class SelectedItem {
  final String type;
  final int quantity;
  final double pricePerKg;
  final double totalPrice;

  SelectedItem({
    required this.type,
    required this.quantity,
    required this.pricePerKg,
    required this.totalPrice,
  });
}