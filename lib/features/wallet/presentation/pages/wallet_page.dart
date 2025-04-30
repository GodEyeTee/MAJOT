// lib/features/wallet/presentation/pages/wallet_page.dart
import 'package:flutter/material.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Wallet Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Your wallet content will appear here',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
