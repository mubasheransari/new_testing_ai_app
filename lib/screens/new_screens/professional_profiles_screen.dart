import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_tneww/Bloc/global_bloc.dart';

class ProfessionalProfilesScreen extends StatefulWidget {
  const ProfessionalProfilesScreen({super.key});

  @override
  State<ProfessionalProfilesScreen> createState() => _ProfessionalProfilesScreenState();
}

class _ProfessionalProfilesScreenState extends State<ProfessionalProfilesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(context.read<GlobalBloc>().state.loginModel!.professionals.first.name)),
    );
  }
}