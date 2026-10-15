// File: ticket_code_test.dart
// Unit test pembaca kode tiket dari hasil pemindaian (QR POS, URL, manual).

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/features/scanner/data/ticket_code.dart';

void main() {
  group('TicketCode.parse', () {
    test('mengambil kode dari payload QR POS', () {
      expect(
        TicketCode.parse(
          'TICKET|code=TKT-4ES7-P7R8-8DSW-95W9|transaction=3|status=active',
        ),
        'TKT-4ES7-P7R8-8DSW-95W9',
      );
      expect(
        TicketCode.parse(
          'TICKET|code=GRP-2HPG-4FWB-GMFR-NRXW|transaction=6|status=active',
        ),
        'GRP-2HPG-4FWB-GMFR-NRXW',
      );
    });

    test('membiarkan kode polos apa adanya', () {
      expect(
        TicketCode.parse('TKT-4ES7-P7R8-8DSW-95W9'),
        'TKT-4ES7-P7R8-8DSW-95W9',
      );
    });

    test('merapikan kode yang diketik dengan spasi dan huruf kecil', () {
      expect(
        TicketCode.parse('  tkt - j23s - cqap - ptek - 4va2  '),
        'TKT-J23S-CQAP-PTEK-4VA2',
      );
    });

    test('mengambil kode dari URL verifikasi', () {
      expect(
        TicketCode.parse(
          'https://tix.example.com/verify?code=TKT-ABCD-2345-MNPQ-RSTU',
        ),
        'TKT-ABCD-2345-MNPQ-RSTU',
      );
    });

    test('kode tak dikenal diteruskan supaya server yang memutuskan', () {
      expect(TicketCode.parse('08221115'), '08221115');
      expect(TicketCode.parse('INV-20261013-WDQ5ZA'), 'INV-20261013-WDQ5ZA');
    });

    test('masukan kosong menjadi string kosong', () {
      expect(TicketCode.parse('   '), '');
      expect(TicketCode.parse(''), '');
    });

    test('looksLikeTicket membedakan kode tiket dari kode lain', () {
      expect(
        TicketCode.looksLikeTicket('TICKET|code=TKT-ABCD-2345-MNPQ-RSTU|'),
        isTrue,
      );
      expect(TicketCode.looksLikeTicket('08221115'), isFalse);
    });

    test('isGroup mendeteksi kode rombongan GRP-', () {
      expect(TicketCode.isGroup('GRP-2HPG-4FWB-GMFR-NRXW'), isTrue);
      expect(
        TicketCode.isGroup(
          'TICKET|code=GRP-2HPG-4FWB-GMFR-NRXW|transaction=6|status=active',
        ),
        isTrue,
      );
      expect(TicketCode.isGroup('TKT-4ES7-P7R8-8DSW-95W9'), isFalse);
      expect(
        TicketCode.isGroup(
          'TICKET|code=TKT-4ES7-P7R8-8DSW-95W9|transaction=3|status=active',
        ),
        isFalse,
      );
    });
  });
}
