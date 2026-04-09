import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';
import 'package:suki_pos/domain/use_cases/maintenance/delete_department.dart';
import 'package:suki_pos/domain/use_cases/maintenance/get_departments.dart';
import 'package:suki_pos/domain/use_cases/maintenance/save_department.dart';
import 'package:suki_pos/presentation/maintenance/department/bloc/department_bloc.dart';

class MockGetDepartments extends Mock implements GetDepartments {}
class MockSaveDepartment extends Mock implements SaveDepartment {}
class MockDeleteDepartment extends Mock implements DeleteDepartment {}

void main() {
  late DepartmentBloc bloc;
  late MockGetDepartments mockGetDepartments;
  late MockSaveDepartment mockSaveDepartment;
  late MockDeleteDepartment mockDeleteDepartment;

  setUpAll(() {
    registerFallbackValue(NoParams());
  });

  setUp(() {
    mockGetDepartments = MockGetDepartments();
    mockSaveDepartment = MockSaveDepartment();
    mockDeleteDepartment = MockDeleteDepartment();
    bloc = DepartmentBloc(
      getDepartments: mockGetDepartments,
      saveDepartment: mockSaveDepartment,
      deleteDepartment: mockDeleteDepartment,
    );
  });

  const tDepartments = [
    Department(id: 1, code: 'D1', name: 'Dept 1'),
  ];

  test('initial state should be DepartmentInitial', () {
    expect(bloc.state, equals(DepartmentInitial()));
  });

  group('GetDepartmentsEvent', () {
    blocTest<DepartmentBloc, DepartmentState>(
      'should emit [DepartmentLoading, DepartmentLoaded] when data is gotten successfully',
      build: () {
        when(() => mockGetDepartments(any()))
            .thenAnswer((_) async => const Right(tDepartments));
        return bloc;
      },
      act: (bloc) => bloc.add(GetDepartmentsEvent()),
      expect: () => [
        DepartmentLoading(),
        const DepartmentLoaded(tDepartments),
      ],
      verify: (_) {
        verify(() => mockGetDepartments(any())).called(1);
      },
    );
  });
}
