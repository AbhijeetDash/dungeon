import 'package:flutter_test/flutter_test.dart';

import 'package:dungeon/core/date_x.dart';
import 'package:dungeon/data/models/booking.dart';
import 'package:dungeon/data/models/slot.dart';

void main() {
  group('DateX', () {
    test('ymd is zero-padded YYYY-MM-DD', () {
      expect(DateX.ymd(DateTime(2026, 6, 9)), '2026-06-09');
    });

    test('parseYmd round-trips a valid date', () {
      final d = DateX.parseYmd('2026-06-09');
      expect(d, isNotNull);
      expect(d!.year, 2026);
      expect(d.month, 6);
      expect(d.day, 9);
    });

    test('parseYmd returns null for garbage', () {
      expect(DateX.parseYmd('not-a-date'), isNull);
    });
  });

  group('Slot', () {
    Slot make(String status) => Slot(
          id: 'x',
          venueId: 'v',
          date: '2026-06-09',
          hour: 9,
          label: '09:00 - 10:00',
          band: TimeOfDayBand.morning,
          status: status,
        );

    test('booked/available derive from status', () {
      expect(make('booked').booked, isTrue);
      expect(make('booked').available, isFalse);
      expect(make('available').available, isTrue);
    });
  });

  group('Booking', () {
    test('timeLabel renders the hour range; isActive reflects status', () {
      const b = Booking(
        id: 'b',
        userId: 'u',
        venueId: 'v',
        date: '2026-06-09',
        hour: 18,
        slotId: 's',
        status: 'active',
        createdAt: '',
      );
      expect(b.timeLabel, '18:00 - 19:00');
      expect(b.isActive, isTrue);
    });
  });
}
