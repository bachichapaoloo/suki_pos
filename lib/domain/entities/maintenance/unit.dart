import 'package:equatable/equatable.dart';

class Unit extends Equatable {
  final int? id;
  final String name;
  final String? abbreviation;
  final double? unitValue;
  final String? baseUnit;
  final bool isGrams;
  final bool isPcs;
  final bool isMl;
  final bool isActive;

  const Unit({
    this.id,
    required this.name,
    this.abbreviation,
    this.unitValue,
    this.baseUnit,
    this.isGrams = false,
    this.isPcs = false,
    this.isMl = false,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, abbreviation, unitValue, baseUnit, isGrams, isPcs, isMl, isActive];
}
