import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const _key = 'isDarkMode';

  ThemeBloc() : super(const ThemeState(themeMode: ThemeMode.light)) {
    on<ToggleThemeEvent>(_onToggleTheme);
    on<LoadThemeEvent>(_onLoadTheme);
    add(LoadThemeEvent());
  }

  Future<void> _onToggleTheme(ToggleThemeEvent event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, event.isDark);
    emit(ThemeState(themeMode: event.isDark ? ThemeMode.dark : ThemeMode.light));
  }

  Future<void> _onLoadTheme(LoadThemeEvent event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? false;
    emit(ThemeState(themeMode: isDark ? ThemeMode.dark : ThemeMode.light));
  }
}

