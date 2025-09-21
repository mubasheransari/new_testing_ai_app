import 'package:equatable/equatable.dart';
import 'package:motives_tneww/Model/login_model.dart';

enum LoginStatus {
  initial,
  loading,
  success,
  failure,
}

enum SignUpStatus {
  initial,
  loading,
  success,
  failure,
}

class GlobalState extends Equatable {
  final LoginStatus loginStatus;
  final SignUpStatus signUpStatus;
  LoginModel? loginModel;
  final String? errorMessageLogin;
  final String? errorMessageSignUp;

  /// Store response data on success (like userId, email, token, etc.)
  final Map<String, dynamic>? loginData;
  final Map<String, dynamic>? signUpData;

   GlobalState({
    this.loginStatus = LoginStatus.initial,
    this.signUpStatus = SignUpStatus.initial,
    this.errorMessageLogin,
    this.loginModel,
    this.errorMessageSignUp,
    this.loginData,
    this.signUpData,
  });

  GlobalState copyWith({
    LoginStatus? loginStatus,
    SignUpStatus? signUpStatus,
    LoginModel? loginModel,
    String? errorMessageLogin,
    String? errorMessageSignUp,
    Map<String, dynamic>? loginData,
    Map<String, dynamic>? signUpData,
  }) {
    return GlobalState(
      loginModel: loginModel ?? this.loginModel,
      loginStatus: loginStatus ?? this.loginStatus,
      signUpStatus: signUpStatus ?? this.signUpStatus,
      errorMessageLogin: errorMessageLogin ?? this.errorMessageLogin,
      errorMessageSignUp: errorMessageSignUp ?? this.errorMessageSignUp,
      loginData: loginData ?? this.loginData,
      signUpData: signUpData ?? this.signUpData,
    );
  }

  @override
  List<Object?> get props => [
        loginModel,
        loginStatus,
        signUpStatus,
        errorMessageLogin,
        errorMessageSignUp,
        loginData,
        signUpData,
      ];
}



// class GlobalState extends Equatable {
//   final LoginStatus loginStatus;
//   final SignUpStatus signUpStatus;
//   final String? errorMessageLogin;

//    GlobalState({
//     this.loginStatus = LoginStatus.initial,
//     this.signUpStatus = SignUpStatus.initial,
//     this.errorMessageLogin,
//   });

//   GlobalState copyWith({
//     LoginStatus? loginStatus,
//     SignUpStatus ? signUpStatus,
//     String? errorMessageLogin,
//   }) {
//     return GlobalState(
//       loginStatus: loginStatus ?? this.loginStatus,
//       signUpStatus:  signUpStatus ?? this.signUpStatus,
//       errorMessageLogin: errorMessageLogin ?? this.errorMessageLogin,
//     );
//   }

//   @override
//   List<Object?> get props => [
//         loginStatus,
//         signUpStatus,
//         errorMessageLogin,
//       ];
// }
