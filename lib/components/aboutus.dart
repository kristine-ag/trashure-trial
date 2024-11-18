import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About Us"),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Center(
              child: Column(
                children: [
                  Text(
                    "About Us",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 4,
                    width: 200,
                    color: Colors.green[700],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Mission Statement
            const Text(
              "We are students from Ateneo de Davao University.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            const Text(
              "This app, Trashure, was created as part of our capstone project for the course Bachelor of Science in Information Systems. It aims to address the critical environmental issues of waste management and recycling in Davao City by providing a platform to connect households, businesses, and recycling facilities seamlessly.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            // Team Introduction
            const Text(
              "Meet Our Team",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 20),
            // Profiles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          AssetImage("assets/images/ashley_noel.jpg"),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Ashley Noel M. Lim",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Lead Developer",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          AssetImage("assets/images/kristine_angela.png"),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Kristine Angela A. Gallawan",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "UI/UX Designer",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Project Purpose
            const Text(
              "Why We Built This App",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 10),
            const Text(
              "Trashure is aligned with the United Nations Sustainable Development Goals (SDGs), particularly SDG 11 (Sustainable Cities and Communities) and SDG 12 (Responsible Consumption and Production). By fostering a culture of recycling and incentivizing proper waste disposal, we aim to create a cleaner and more sustainable environment.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            // Contact Us Section
            const Text(
              "Contact Us",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.email, color: Colors.green),
                SizedBox(width: 10),
                Text(
                  "anmlim@addu.edu.ph",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.email, color: Colors.green),
                SizedBox(width: 10),
                Text(
                  "kaagallawan@addu.edu.ph",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Footer
            const Center(
              child: Text(
                "Thank you for supporting sustainable practices!",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
