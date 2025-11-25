import 'package:equatable/equatable.dart';

abstract class GlobalEvent extends Equatable {
  const GlobalEvent();

  @override
  List<Object> get props => [];
}

// ignore: must_be_immutable
class Login extends GlobalEvent {
  Login({this.email, this.password});

  String? email, password;

  @override
  List<Object> get props => [email!, password!];
}

class SignUp extends GlobalEvent {
  SignUp({this.name,this.email, this.password,this.userType});

  String? name, email, password, userType;

  @override
  List<Object> get props => [name!,email!, password!,userType!];
}