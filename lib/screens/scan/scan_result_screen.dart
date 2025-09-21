import 'package:flutter/material.dart';

import '../../Model/scanjuicemodel.dart';

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key, required this.result});

  final ScanJuiceResponse result;

  static const accent = Color(0xFFE97C42);

  @override
  Widget build(BuildContext context) {
    final user = result.user;

    Widget row(String k, String? v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                  width: 140,
                  child: Text(k,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              const SizedBox(width: 8),
              Expanded(child: Text(v ?? '-', overflow: TextOverflow.ellipsis)),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header like login
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scan Result'.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const SizedBox(
                    width: 130,
                    height: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Great job!',
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w700)),
                        SizedBox(height: 6),
                        Text('Here are your scan details.',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const _DecorShapes(),
                ],
              ),

              const SizedBox(height: 18),

              Card(
                elevation: 0,
                color: const Color(0xFFF4F5F7),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                              result.success ? Icons.check_circle : Icons.error,
                              color:
                                  result.success ? Colors.green : Colors.red),
                          const SizedBox(width: 8),
                          Text(result.success ? 'Success' : 'Failed',
                              style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (result.message != null)
                        Text(result.message!,
                            style: Theme.of(context).textTheme.bodyMedium),
                      const Divider(height: 24),
                      row('Detected Color', result.detectedColor),
                      row('Points Awarded', result.pointsAwarded?.toString()),
                      row('Total Points', result.totalPoints?.toString()),
                    ],
                  ),
                ),
              ),

             /* if (user != null) ...[
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: const Color(0xFFF4F5F7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('User',
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        const SizedBox(height: 8),
                        row('ID', user.id.toString()),
                        row('Name', user.name),
                        row('Email', user.email),
                        row('Gender', user.gender),
                        row('Age', user.age?.toString()),
                        row('Height', user.height?.toString()),
                        row('Weight', user.weight?.toString()),
                        row('Reward Points', user.rewardPoints?.toString()),
                      ],
                    ),
                  ),
                ),
              ],*/

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Scan Another',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecorShapes extends StatelessWidget {
  const _DecorShapes();

  @override
  Widget build(BuildContext context) {
    const light = Color(0xFFFFE1D2);
    const mid = Color(0xFFF6B79C);
    const dark = Color(0xFFE97C42);

    Widget block(Color c, {double w = 84, double h = 26, double angle = .6}) {
      return Transform.rotate(
        angle: angle,
        child: Container(
          width: w,
          height: h,
          decoration:
              BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)),
        ),
      );
    }

    return SizedBox(
      width: 110,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -6, top: 0, child: block(light)),
          Positioned(right: 6, top: 22, child: block(mid, w: 78)),
          Positioned(right: -12, top: 48, child: block(dark, w: 64, h: 22)),
        ],
      ),
    );
  }
}



// class ResultPage extends StatelessWidget {
//   final ScanJuiceResponse result;
//   const ResultPage({super.key, required this.result});

//   @override
//   Widget build(BuildContext context) {
//     final user = result.user;
//     return Scaffold(
//       appBar: AppBar(title: const Text('Scan Result')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Card(
//           elevation: 1,
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Row(children: [
//                 Icon(result.success ? Icons.check_circle : Icons.error,
//                     color: result.success ? Colors.green : Colors.red, size: 28),
//                 const SizedBox(width: 8),
//                 Text(result.success ? 'Success' : 'Failed',
//                     style: Theme.of(context).textTheme.titleLarge),
//               ]),
//               const SizedBox(height: 8),
//               if (result.message != null)
//                 Text(result.message!, style: Theme.of(context).textTheme.bodyMedium),
//               const Divider(height: 24),
//               _info('Detected Color', result.detectedColor),
//               _info('Points Awarded', result.pointsAwarded?.toString()),
//               _info('Total Points', result.totalPoints?.toString()),
//               if (user != null) ...[
//                 const Divider(height: 24),
//                 Text('User', style: Theme.of(context).textTheme.titleMedium),
//                 const SizedBox(height: 8),
//                 _info('ID', user.id.toString()),
//                 _info('Name', user.name),
//                 _info('Email', user.email),
//                 _info('Gender', user.gender),
//                 _info('Age', user.age?.toString()),
//                 _info('Height', user.height?.toString()),
//                 _info('Weight', user.weight?.toString()),
//                 _info('Reward Points', user.rewardPoints?.toString()),
//               ],
//             ]),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _info(String k, String? v) => Padding(
//         padding: const EdgeInsets.symmetric(vertical: 6),
//         child: Row(children: [
//           SizedBox(width: 140, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
//           const SizedBox(width: 8),
//           Expanded(child: Text(v ?? '-', overflow: TextOverflow.ellipsis)),
//         ]),
//       );
// }
