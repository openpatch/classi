import 'package:clari/core/database/app_database.dart';
import 'package:clari/features/groups/group_repository.dart';
import 'package:clari/features/students/student_repository.dart';
import 'package:clari/shared/utils/grade_categories.dart';
import 'package:clari/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late GroupRepository groupRepository;
  late StudentRepository studentRepository;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
    groupRepository = GroupRepository(database);
    studentRepository = StudentRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('archive and clone keep group data usable', () async {
    final sourceGroupId = await groupRepository.createGroup(
      name: '10A',
      colorHex: '#FF3949AB',
      gradeScale: defaultGradeScaleEntries,
      gradeCategories: const [
        GradeCategory(
          id: 'essay',
          name: 'Essay',
          weight: 2,
          colorHex: '#FF6D4C41',
        ),
      ],
    );

    await studentRepository.addStudent(
      groupId: sourceGroupId,
      firstName: 'Ada',
      lastName: 'Lovelace',
      originNote: 'Maths',
    );

    await groupRepository.archiveGroup(sourceGroupId);

    final archivedGroups = await groupRepository.watchArchivedGroups().first;
    expect(archivedGroups.single.id, sourceGroupId);
    expect(archivedGroups.single.archivedAt, isNotNull);

    final clonedGroupId = await groupRepository.cloneGroup(
      sourceGroupId: sourceGroupId,
      newName: '10A Copy',
    );
    final clonedStudents = await studentRepository
        .watchByGroup(clonedGroupId)
        .first;
    final clonedGroup = await groupRepository.watchGroup(clonedGroupId).first;

    expect(clonedStudents, hasLength(1));
    expect(clonedStudents.single.firstName, 'Ada');
    expect(clonedStudents.single.lastName, 'Lovelace');
    expect(
      parseGradeCategories(clonedGroup!.gradeCategoriesJson).single.name,
      'Essay',
    );
    expect(
      parseGradeCategories(clonedGroup.gradeCategoriesJson).single.colorHex,
      '#FF6D4C41',
    );
    expect(clonedGroup.colorHex, '#FF3949AB');
  });
}
