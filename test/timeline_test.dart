import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puvi/features/timeline/data/timeline_item.dart';
import 'package:puvi/features/timeline/data/timeline_repository.dart';
import 'package:puvi/features/timeline/presentation/timeline_tab.dart';
import 'package:puvi/features/timeline/presentation/widgets/timeline_milestone_card.dart';

void main() {
  group('TimelineItem Model Tests', () {
    test('Parses complete JSON milestone correctly', () {
      final json = {
        '_id': 'test_123',
        'title': 'The First Sight',
        'date': '2026-04-01',
        'note': 'It was the first Date , meetup and everything was magical',
        'location': 'Lanka BHU & VT, Varanasi',
        'imageUrl': 'https://firebasestorage.googleapis.com/...',
        'category': 'Firsts',
        'authorName': 'Vicky',
        'coupleId': 'puvi_couple',
        'coordinates': {'lat': 25.289, 'lng': 83.006},
        'isFavorite': true,
        'createdAt': '2026-04-01T12:00:00.000Z',
      };

      final item = TimelineItem.fromJson(json);

      expect(item.id, 'test_123');
      expect(item.title, 'The First Sight');
      expect(item.date, DateTime(2026, 4, 1));
      expect(item.category, 'Firsts');
      expect(item.authorName, 'Vicky');
      expect(item.hasImage, isTrue);
      expect(item.hasLocation, isTrue);
      expect(item.hasNote, isTrue);
      expect(item.isFavorite, isTrue);
      expect(item.formattedDate, 'April 1, 2026');
      expect(item.postalStampDate, '01 APR 2026');
      expect(item.yearString, '2026');
    });

    test('Handles missing / null fields gracefully with safe fallbacks', () {
      final json = {'id': 'test_empty', 'date': '2026-05-13'};

      final item = TimelineItem.fromJson(json);

      expect(item.id, 'test_empty');
      expect(item.title, 'Untitled Memory');
      expect(item.note, '');
      expect(item.location, isNull);
      expect(item.imageUrl, isNull);
      expect(item.hasImage, isFalse);
      expect(item.hasLocation, isFalse);
      expect(item.hasNote, isFalse);
      expect(item.category, 'Milestones');
      expect(item.authorName, 'Puja & Vicky');
      expect(item.isFavorite, isFalse);
    });

    test('Serializes to JSON accurately', () {
      final item = TimelineItem(
        id: 'anniv_1',
        title: 'The Day We Became Us 💍',
        date: DateTime(2026, 4, 11),
        note: 'Our eternal beginning',
        location: 'Varanasi',
        category: 'Anniversary',
        authorName: 'Puja & Vicky',
        createdAt: DateTime(2026, 4, 11),
      );

      final json = item.toJson();
      expect(json['id'], 'anniv_1');
      expect(json['title'], 'The Day We Became Us 💍');
      expect(json['date'], '2026-04-11');
      expect(json['category'], 'Anniversary');
      expect(json['authorName'], 'Puja & Vicky');
    });
  });

  group('TimelineRepository CRUD & Filtering Tests', () {
    late TimelineRepository repo;

    setUp(() {
      repo = TimelineRepository();
    });

    test('Adds, filters, sorts and deletes milestones in memory', () async {
      await repo.initialize();

      final itemA = TimelineItem(
        id: 'test_a',
        title: 'First Chat',
        date: DateTime(2025, 11, 22),
        category: 'Firsts',
        authorName: 'Puja',
        createdAt: DateTime(2025, 11, 22),
      );

      final itemB = TimelineItem(
        id: 'test_b',
        title: 'Anniversary Day',
        date: DateTime(2026, 4, 11),
        category: 'Anniversary',
        authorName: 'Puja & Vicky',
        isFavorite: true,
        createdAt: DateTime(2026, 4, 11),
      );

      await repo.addMilestone(itemA);
      await repo.addMilestone(itemB);

      // 1. Chronological sorting (oldest first: 2025 before 2026)
      final chronological = await repo.getMilestones(newestFirst: false);
      final indexA = chronological.indexWhere((i) => i.id == 'test_a');
      final indexB = chronological.indexWhere((i) => i.id == 'test_b');
      expect(indexA, lessThan(indexB));

      // 2. Newest first sorting (2026 before 2025)
      final reverse = await repo.getMilestones(newestFirst: true);
      final revIndexA = reverse.indexWhere((i) => i.id == 'test_a');
      final revIndexB = reverse.indexWhere((i) => i.id == 'test_b');
      expect(revIndexB, lessThan(revIndexA));

      // 3. Category filtering
      final firstsOnly = await repo.getMilestones(categoryFilter: 'Firsts');
      expect(firstsOnly.any((i) => i.id == 'test_a'), isTrue);
      expect(firstsOnly.any((i) => i.id == 'test_b'), isFalse);

      // 4. Favorites filtering
      final favorites = await repo.getMilestones(categoryFilter: 'Favorites');
      expect(favorites.any((i) => i.id == 'test_b'), isTrue);

      // 5. Update
      final updatedA = itemA.copyWith(title: 'Our First Conversation');
      await repo.updateMilestone(updatedA);
      final afterUpdate = await repo.getMilestones();
      final foundA = afterUpdate.firstWhere((i) => i.id == 'test_a');
      expect(foundA.title, 'Our First Conversation');

      // 6. Delete
      await repo.deleteMilestone('test_a');
      final afterDelete = await repo.getMilestones();
      expect(afterDelete.any((i) => i.id == 'test_a'), isFalse);
    });
  });

  group('Timeline Presentation Widget Tests', () {
    testWidgets('TimelineTab renders editorial header, filters, and cards', (
      tester,
    ) async {
      final repo = TimelineRepository();
      await repo.initialize();
      await repo.addMilestone(
        TimelineItem(
          id: 'sample_date',
          title: 'Our First Date',
          date: DateTime(2026, 4, 1),
          note: 'A magical evening together',
          location: 'Varanasi',
          category: 'Firsts',
          authorName: 'Vicky',
          createdAt: DateTime(2026, 4, 1),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimelineTab(userName: 'Vicky', repository: repo),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify editorial title and couple subtitle
      expect(find.text('Our Story'), findsOneWidget);
      expect(
        find.text('Puja & Vicky • Together since April 11, 2026'),
        findsOneWidget,
      );
      expect(find.textContaining('Chapters'), findsOneWidget);

      // Verify category filters
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Anniversary'), findsWidgets);
      expect(find.text('Firsts'), findsWidgets);
      expect(find.text('Dates'), findsWidgets);
      expect(find.text('Milestones'), findsWidgets);

      // Verify Add Chapter FAB exists
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Verify milestones list cards rendered
      expect(find.byType(TimelineMilestoneCard), findsWidgets);
    });
  });
}
