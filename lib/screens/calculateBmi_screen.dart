import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_tneww/screens/login_screen.dart';
import 'package:motives_tneww/theme_change/theme_bloc.dart';
import 'package:motives_tneww/theme_change/theme_event.dart';

import '../widget/gradient_button.dart';
import '../widget/shader_mask_text.dart';

class CalculateBMIView extends StatefulWidget {
  const CalculateBMIView({super.key});

  @override
  State<CalculateBMIView> createState() => _CalculateBMIViewState();
}

class _CalculateBMIViewState extends State<CalculateBMIView> {
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeBloc>().state.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Align(
          alignment: Alignment.centerLeft,
          child: ShaderMaskText(
            text: "Hello , TestUser",
            textxfontsize: 22,
          ),
        ),
        //  backgroundColor: Color(0xFF121212),
        elevation: 0,
        actions: [
          // ShaderMaskText(text:isDark ?  "Change to Light":"Change to Dark", textxfontsize: 13),
          Transform.scale(
            scale: 0.48,
            child: Switch(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: isDark,
              activeColor: Colors.purple,
              onChanged: (value) {
                context.read<ThemeBloc>().add(ToggleThemeEvent(value));
              },
            ),
          ),
        ],
      ),
      // backgroundColor: Colors.black,
      // appBar: AppBar(
      //   title: const Text("Calculate BMI", style: TextStyle(color: Colors.white)),
      //   backgroundColor: Colors.black,
      //   iconTheme: const IconThemeData(color: Colors.white),
      //   actions: const [
      //     Padding(
      //       padding: EdgeInsets.only(right: 16.0),
      //       child: Icon(Icons.notifications_none, color: Colors.white),
      //     ),
      //   ],
      // ),
      // drawer: Drawer(
      //   backgroundColor: Colors.grey[900],
      //   child: ListView(
      //     children: const [
      //       DrawerHeader(
      //         decoration: BoxDecoration(color: Colors.deepPurple),
      //         child: Text("Menu", style: TextStyle(color: Colors.white)),
      //       ),
      //       ListTile(
      //         leading: Icon(Icons.home, color: Colors.white),
      //         title: Text("Home", style: TextStyle(color: Colors.white)),
      //       ),
      //     ],
      //   ),
      // ),
      body: BMIScreen(),
    );
  }
}

class BMIScreen extends StatefulWidget {
  @override
  _BMIScreenState createState() => _BMIScreenState();
}

class _BMIScreenState extends State<BMIScreen> {
  bool isMale = true;
  double height = 180;
  int age = 19;
  int weight = 74;
  final Color primaryBlue = const Color(0xFF5D6EFF);
  final Color lightBlue = const Color(0xFF8A97FF);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              Container(
                width: 120,
                height: 35,
                alignment: Alignment.centerRight,
                child: GradientButton(
                  text: 'Scan Image',
                 // fontSize: 14,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ShaderMaskText(
            text: "Body Mass Index (BMI)",
            textxfontsize: 22,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _genderCard("Male", "assets/male_icon.png", isMale),
              const SizedBox(width: 20),
              _genderCard("Female", "assets/female.png", !isMale),
            ],
          ),
          const SizedBox(height: 30),
          _heightCard(),
          const SizedBox(height: 20),
          Row(
            children: [
              _numberCard("age", age, () => setState(() => age--),
                  () => setState(() => age++)),
              const SizedBox(width: 20),
              _numberCard("weight", weight, () => setState(() => weight--),
                  () => setState(() => weight++)),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 250,
              height: 45,
              child: GradientButton(
                text: 'Calculate Your BMI',
                onTap: () {
                  showBmi("90", context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

// BMI Screen UI
/*class BMIScreen extends StatefulWidget {
  @override
  _BMIScreenState createState() => _BMIScreenState();
}

class _BMIScreenState extends State<BMIScreen> {
  bool isMale = true;
  double height = 180;
  int age = 19;
  int weight = 74;
  final Color primaryBlue = const Color(0xFF5D6EFF);
  final Color lightBlue = const Color(0xFF8A97FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //   backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Container(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(),
                Container(
                  width: 120,
                  height: 35,
                  alignment: Alignment.centerRight,
                  child: GradientButton(
                      text: 'Scan Image', fontSize: 14, onTap: () {}),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            ShaderMaskText(
              text: "Body Mass Index (BMI)",
              textxfontsize: 22,
            ),
            // const Text(
            //   "Body Mass Index (BMI)",
            //   style: TextStyle(color: Colors.white, fontSize: 18),
            // ),
            const SizedBox(height: 20),
            Row(
              children: [
                _genderCard("Male", "assets/male_icon.png", isMale),
                const SizedBox(width: 20),
                _genderCard("Female", "assets/female.png", !isMale),
              ],
            ),
            const SizedBox(height: 30),
            _heightCard(),
            const SizedBox(height: 20),
            Row(
              children: [
                _numberCard("age", age, () => setState(() => age--),
                    () => setState(() => age++)),
                const SizedBox(width: 20),
                _numberCard("weight", weight, () => setState(() => weight--),
                    () => setState(() => weight++)),
              ],
            ),
            const Spacer(),
            GradientButton(
                text: 'Calculate Your BMI',
                onTap: () {
                  showBmi("90", context);
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => BMIResultScreen(bmiValue: 90.7),
                  //   ),
                  // );
                })
            /* InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BMIResultScreen(bmiValue: 90.7),
                  ),
                );
              },
              child: Container(
                width: 250,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: const Center(
                  child: Text(
                    "CALCULATE YOUR BMI",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),*/
          ],
        ),
      ),
    );
  }*/

  Widget _genderCard(String label, String asset, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isMale = (label == "Male")),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: active ? Colors.deepPurple[300] : Colors.grey[800],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage(asset),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heightCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Text("HEIGHT", style: TextStyle(color: Colors.white70)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                height.toInt().toString(),
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const Text(" cm",
                  style: TextStyle(fontSize: 20, color: Colors.white)),
            ],
          ),
          Slider(
            value: height,
            min: 120,
            max: 220,
            activeColor: lightBlue,
            onChanged: (val) => setState(() => height = val),
          ),
        ],
      ),
    );
  }

  Widget _numberCard(
      String label, int value, VoidCallback onMinus, VoidCallback onPlus) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(value.toString(),
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circleButton(Icons.remove, onMinus),
                const SizedBox(width: 10),
                _circleButton(Icons.add, onPlus),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: const CircleAvatar(
        backgroundColor: Colors.white,
        radius: 20,
        child: Icon(Icons.remove, color: Colors.black54),
      ),
    );
  }
}

showBmi(String value, BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      final isDark =
          context.watch<ThemeBloc>().state.themeMode == ThemeMode.dark;
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMaskText(
                text: 'BMI Result',
                textxfontsize: 22,
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  const SizedBox(width: 32),
                  Text('Your BMI result is : ',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 22)),
                  ShaderMaskText(
                    text: '$value',
                    textxfontsize: 22,
                  ),
                  // Text(value, style:
                  //         TextStyle(fontWeight: FontWeight.w500, fontSize: 22)),
                ],
              ),

              const SizedBox(height: 15),
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  height: 45,
                  width: 120,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.cyan, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )

              // ElevatedButton(
              //   onPressed: () => Navigator.pop(context),
              //   child: Text('Close',style: TextStyle(color: Colors.white),),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.blueAccent,
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(10),
              //     ),
              //     padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              //   ),
              // )
            ],
          ),
        ),
      );
    },
  );
}
