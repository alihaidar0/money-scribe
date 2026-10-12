import 'package:equatable/equatable.dart';

/// Who the signed-in person is, as the account shows it.
final class AccountProfile extends Equatable {
  const new({required this.name, required this.email});

  final String name;
  final String email;

  /// The first letter of the name, in capitals, for the round picture that
  /// stands in for a photo. A name with no letters gives a question mark.
  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }

  @override
  List<Object> get props => [name, email];
}
