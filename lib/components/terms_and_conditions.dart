// ignore_for_file: prefer_const_declarations

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Import the package

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String termsContent = '''
# Steps and Terms and Conditions

## How to Segregate Your Trash and Book a Collection Service

### Step 1: Segregate Your Trash

Proper segregation of trash is essential for efficient recycling and disposal. Follow these guidelines to separate your waste:

#### Biodegradable Waste

- Includes food scraps, garden waste, and other organic materials that decompose naturally.
- Place in a separate bag or bin labeled "Biodegradable."

#### Non-biodegradable Waste/Recyclables

- Includes plastics, metals, glass, and other materials that do not decompose.
- Sort into categories:
  - **Plastic**: bottles, bags, containers.
  - **Glass**: bottles, jars (be sure to clean these before disposal).
  - **Metal**: cans, foil, aluminum.
  - **Paper**: newspapers, magazines, cardboard.
- Place each type of non-biodegradable waste into separate bags or bins to simplify collection.

#### Hazardous Waste

- Includes batteries, light bulbs, and chemicals.
- These should be stored safely and disposed of properly through authorized disposal programs (not included in the regular collection service).

### Step 2: Booking a Collection Service

Once you’ve properly segregated your waste, you’re ready to book a collection service through the website. Here’s how it works:

#### Measure Your Recyclables

- Use a weighing scale to measure the weight of your sorted recyclables (plastic, metal, glass, and paper).
- This step helps us estimate the value of your recyclables before collection.

#### Select Recyclables and Their Weight

- In the website, choose the category of recyclables you have (e.g., plastic, metal, glass).
- Enter the weight for each category. The website will calculate the estimated value based on current market prices.

#### Choose Your Location

- Input your address or choose from your saved locations. This helps us determine the nearest collection team for your area.

#### Pick a Schedule

- Select a specific date and time for the collection service from the available options.
- We offer flexible scheduling to fit your convenience.
- Ensure your recyclables are packed and ready for pickup at the scheduled time.

### Step 3: Collection and Payment

- On the scheduled date, our team will arrive at your location to collect your segregated trash.
- They will verify the weight and quality of the recyclables, after which the payment will be credited to your website account.
- You can then request a withdrawal through GCash once you reach the minimum required balance.

‎ 
---
---
‎ 

## Terms and Conditions

### 1. Introduction

Welcome to Trashure. By accessing or using our website, you agree to comply with and be bound by the following terms and conditions. Please review these terms carefully before using the service.

### 2. Service Overview

The website provides a platform for users to schedule garbage collection services and sell eligible recyclables. All services are subject to availability and confirmation of the service request.

### Garbage Collection Services

#### 3. Pricing and Charges

- Prices for garbage collection services may fluctuate based on market conditions and operational costs. We reserve the right to adjust pricing at any time without prior notice.
- An initial charge will apply upon booking a collection service. This charge covers the basic service and is non-refundable unless otherwise specified.
- Additional charges may apply for services outside of regular collection or for special requests.

#### 4. Payment Terms

- Payments are due upon booking confirmation. Failure to complete payment may result in cancellation of your service request.
- Payment methods accepted will be specified within the website, and users are responsible for ensuring their payment details are up to date.

#### 5. Cancellations and Refunds

- Users may cancel a booking a day before their scheduled booking date. However, cancellations after the allotted period may incur a cancellation fee.
- Refunds, if applicable, will be processed according to our refund policy.

### Sale of Recyclables

#### 6. Selling Non-Biodegradable Recyclables to Trashure

- Users can sell non-biodegradable recyclable materials to Trashure through the website’s collection service.
- Non-biodegradable materials include plastics, metals, glass, and paper. These must be segregated and properly sorted before pickup.
- **Note:** We only accept and purchase non-biodegradable recyclables. We do not buy biodegradable waste, such as food scraps, garden waste, or any other organic materials. Users are responsible for properly disposing of biodegradable waste through alternative methods.
- The recyclables will be assessed, and the amount payable will be calculated based on the current market value of the materials.
- Payment will be credited to the user's account on the website once the materials have been received and processed.

#### 7. Minimum Withdrawal Amount

- Users must accumulate a minimum balance of 300 pesos before they are eligible to request a withdrawal.
- Withdrawals can be requested through the website once this minimum balance is reached.

#### 8. Withdrawal Process

- Withdrawals are processed through GCash. Users must have a valid and active GCash account linked to their website profile.
- After submitting a withdrawal request, funds will be transferred to the user’s GCash account within 0-3 business days.
- Any fees related to GCash transactions are the responsibility of the user.

#### 9. Restrictions on Withdrawals

- Withdrawals below the minimum required amount will not be processed.
- Users are allowed to request withdrawals only after their recyclables have been fully processed and the corresponding payment has been credited to their website account.

#### 10. Payment Discrepancies

- If there is any discrepancy in the amount credited for recyclables, users must report it within 3 days after receiving the payment. Trashure will investigate and resolve the issue promptly.

### Use of User Information

#### 11. Data Collection and Use

- We collect personal information necessary to facilitate the booking and provision of services, including but not limited to your name, contact details, and address.
- Your information may be used to provide services, communicate service updates, and improve the user experience.
- We value your privacy and are committed to protecting your personal data in accordance with applicable data protection laws. For more details, refer to our Privacy Policy.

### General Terms

#### 12. Limitation of Liability

- Trashure is not liable for any damages, losses, or injuries that result from the use of the service, including but not limited to missed collections, delays, or damage to property.
- Trashure is also not responsible for any loss of earnings, incorrect payments, or delays in withdrawals via GCash due to issues related to user accounts or external services.

#### 13. Changes to Terms

- We reserve the right to modify these terms at any time. Any changes will be posted on the website and take effect immediately. Continued use of the website after changes are posted signifies your acceptance of the updated terms.

#### 14. Governing Law

- These terms and conditions are governed by and construed in accordance with the laws of Davao City, Philippines, and you irrevocably submit to the exclusive jurisdiction of the courts in that location.
''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
      ),
      body: Markdown(
        data: termsContent,
        styleSheet: MarkdownStyleSheet(
          h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          h2: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          h3: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          h4: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          p: const TextStyle(fontSize: 16),
          listBullet: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
