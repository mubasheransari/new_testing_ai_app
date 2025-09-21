import 'package:flutter/material.dart';

import '../../Model/scanjuicemodel.dart';


class ResultPage extends StatelessWidget {
  final ScanJuiceResponse result;
  const ResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final user = result.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(result.success ? Icons.check_circle : Icons.error,
                    color: result.success ? Colors.green : Colors.red, size: 28),
                const SizedBox(width: 8),
                Text(result.success ? 'Success' : 'Failed',
                    style: Theme.of(context).textTheme.titleLarge),
              ]),
              const SizedBox(height: 8),
              if (result.message != null)
                Text(result.message!, style: Theme.of(context).textTheme.bodyMedium),
              const Divider(height: 24),
              _info('Detected Color', result.detectedColor),
              _info('Points Awarded', result.pointsAwarded?.toString()),
              _info('Total Points', result.totalPoints?.toString()),
              if (user != null) ...[
                const Divider(height: 24),
                Text('User', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _info('ID', user.id.toString()),
                _info('Name', user.name),
                _info('Email', user.email),
                _info('Gender', user.gender),
                _info('Age', user.age?.toString()),
                _info('Height', user.height?.toString()),
                _info('Weight', user.weight?.toString()),
                _info('Reward Points', user.rewardPoints?.toString()),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _info(String k, String? v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(width: 140, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Expanded(child: Text(v ?? '-', overflow: TextOverflow.ellipsis)),
        ]),
      );
}
