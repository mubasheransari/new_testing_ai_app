import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_tneww/Bloc/global_event.dart';
import 'package:motives_tneww/Bloc/global_state.dart';
import 'package:motives_tneww/Repository/repository.dart';

class GlobalBloc extends Bloc<GlobalEvent, GlobalState> {
  GlobalBloc() : super(GlobalState()) {
    on<Login>(_login);
    on<SignUp>(signup);
  }

  Repository repo = Repository();
  _login(
    Login event,
    emit,
  ) async {
    emit(state.copyWith(loginStatus: LoginStatus.loading));

    try {
      final loginModel = await repo.login(
        event.email ?? "",
        event.password ?? "",
      );

      // Debug prints
      print("Access Token: ${loginModel.accessToken}");
      print("User Name: ${loginModel.user.name}");

      // Save token in GetStorage
      final box = GetStorage();
      box.write('auth_token', loginModel.accessToken);

      // Emit success with model
      emit(state.copyWith(
        loginStatus: LoginStatus.success,
        loginModel: loginModel,
      ));
    } catch (e) {
      print("Login Error: $e");
      emit(state.copyWith(loginStatus: LoginStatus.failure));
    }
  }

//   _login(
//     Login event,
//     emit,
//   ) async {
//     emit(state.copyWith(loginStatus: LoginStatus.loading));

//     try {
//       final response = await repo.login(
//         event.email ?? "",
//         event.password ?? "",
//       );

//       print("Status Code: ${response.statusCode}");
//       print("RESPONSE: ${response}");

//       if (response.statusCode == 200) {
//         emit(state.copyWith(
//             loginStatus: LoginStatus.success, loginModel: response));
//         final box = GetStorage();

// // Save token
//         box.write('auth_token', 'my_jwt_token_here');
//       } else {
//         emit(state.copyWith(
//           loginStatus: LoginStatus.failure,
//         ));
//       }
//     } catch (e) {
//       emit(state.copyWith(
//         loginStatus: LoginStatus.failure,
//       ));
//     }
//   }

  signup(SignUp event, emit) async {
    emit(state.copyWith(signUpStatus: SignUpStatus.loading));

    try {
      final response = await repo.signUp(
        event.name ?? "",
        event.email ?? "",
        event.password ?? "",
        event.userType ??""
      );

      print("Status Code: ${response.statusCode}");
      print("RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final userData = data["data"];
        print("DATA $data");
        print("DATA $data");
        print("DATA $data");

        emit(state.copyWith(
          signUpStatus: SignUpStatus.success,
          errorMessageSignUp: null,
        ));
      } else {
        final data = jsonDecode(response.body);
        emit(state.copyWith(
          signUpStatus: SignUpStatus.failure,
          errorMessageSignUp: data["message"],
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        signUpStatus: SignUpStatus.failure,
        errorMessageSignUp: "Signup API failed: $e",
      ));
    }
  }

  // signup(
  //   SignUp event,
  //   emit,
  // ) async {
  //   emit(state.copyWith(signUpStatus: SignUpStatus.loading));

  //   try {
  //     final response = await repo.signUp(
  //       event.name ?? "",
  //       event.email ?? "",
  //       event.password ?? "",
  //     );

  //     print("Status Code: ${response.statusCode}");
  //       print("RESPONSE: ${response}");

  //     if (response.statusCode == 200) {
  //       emit(state.copyWith(signUpStatus: SignUpStatus.success));
  //     } else {
  //       emit(state.copyWith(
  //        signUpStatus: SignUpStatus.failure,
  //       ));
  //     }
  //   } catch (e) {
  //     emit(state.copyWith(
  //      signUpStatus: SignUpStatus.failure,
  //      errorMessageLogin: e.toString()
  //     ));
  //   }
  // }
}
