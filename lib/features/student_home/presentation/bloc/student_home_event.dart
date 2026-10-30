import 'package:equatable/equatable.dart';

sealed class StudentHomeEvent extends Equatable {
  const StudentHomeEvent();

  @override
  List<Object?> get props => [];
}

class StudentHomeRequested extends StudentHomeEvent {
  const StudentHomeRequested();
}
