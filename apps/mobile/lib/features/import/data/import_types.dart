import 'package:ourney_core/ourney_core.dart';

import 'import_draft.dart';
import 'import_job.dart';

/// Figma wire label of a retold journey's type, mapped onto the data
/// templates. There is no couple type: a couple journey needs both names and
/// the couple skin, which a retold (solo) journey cannot have.
class ImportType {
  const ImportType(this.id, this.template);
  final String id;
  final TemplateId template;
}

const List<ImportType> importTypes = [
  ImportType('weight', TemplateId.weightLoss),
  ImportType('study', TemplateId.englishDaily),
  ImportType('trip', TemplateId.travel),
  ImportType('workout', TemplateId.workout30),
  ImportType('custom', TemplateId.custom),
];

/// Layouts offered for [typeId] (short ids): some need data a retold journey
/// does not have, so they only show for the type that uses them.
List<String> importLayoutsFor(String typeId) => [
  'memory',
  'minimal',
  if (typeId == 'weight') 'quiet',
  if (typeId == 'workout') 'flexer',
];

/// The picker's short layout id as the persona skin the server stores.
PersonaSkinId importSkinId(String layout) => switch (layout) {
  'quiet' => PersonaSkinId.quietTransformer,
  'flexer' => PersonaSkinId.aestheticFlexer,
  'minimal' => PersonaSkinId.minimalistHabit,
  _ => PersonaSkinId.memoryCollectors,
};

/// The short layout id of a stored skin (the inverse of [importSkinId]).
String importLayoutOf(PersonaSkinId? skin) => switch (skin) {
  PersonaSkinId.quietTransformer => 'quiet',
  PersonaSkinId.aestheticFlexer => 'flexer',
  PersonaSkinId.minimalistHabit => 'minimal',
  _ => 'memory',
};

/// The stored job for the chosen photos: dated photos in timeline order, each
/// keeping its own id (the id of its check-in) and its time of day.
ImportJob buildImportJob({
  required String id,
  required String ownerId,
  required String title,
  required ImportType type,
  required String layout,
  required bool continues,
  required String timezone,
  required Iterable<DraftPhoto> photos,
  required DateTime now,
}) {
  final sorted = datedSorted(photos);
  assert(sorted.isNotEmpty, 'a job needs at least one dated photo');
  return ImportJob(
    id: id,
    title: title.trim(),
    emoji: templateFor(type.template).emoji,
    templateId: type.template,
    firstDate: sorted.first.date!,
    lastDate: sorted.last.date!,
    timezone: timezone,
    layout: importSkinId(layout),
    continues: continues,
    createdAt: now,
    ownerId: ownerId,
    photos: [
      for (var i = 0; i < sorted.length; i++)
        ImportJobPhoto(
          id: sorted[i].id,
          position: i,
          sourcePath: sorted[i].path,
          date: sorted[i].date!,
          secondsOfDay: sorted[i].secondsOfDay,
          offsetMinutes: sorted[i].offsetMinutes,
          dedupeKey: sorted[i].dedupeKey,
        ),
    ],
  );
}
