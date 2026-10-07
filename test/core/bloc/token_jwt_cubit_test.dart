import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/bloc/token_jwt/token_jwt_cubit.dart';
import 'package:mobile_tix/core/bloc/token_jwt/token_jwt_state.dart';
import 'package:mobile_tix/core/data/dao/token_jwt_dao.dart';
import 'package:mobile_tix/core/services/encryption_service.dart';

// Manual mock implementation for TokenJwtDAO
class MockTokenJwtDAO implements TokenJwtDAO {
  String? _token;
  bool _shouldThrow = false;

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveToken(String token) async {
    if (_shouldThrow) throw Exception('Save failed');
    _token = token;
  }

  @override
  String? getToken() {
    if (_shouldThrow) throw Exception('Get failed');
    return _token;
  }

  @override
  bool hasToken() => _token != null && _token!.isNotEmpty;

  @override
  Future<void> deleteToken() async {
    if (_shouldThrow) throw Exception('Delete failed');
    _token = null;
  }

  @override
  Future<void> clear() async {
    _token = null;
  }

  @override
  Future<void> close() async {}

  void setShouldThrow(bool value) => _shouldThrow = value;
}

void main() {
  group('TokenJwtCubit Tests', () {
    late MockTokenJwtDAO mockDao;
    late TokenJwtCubit cubit;

    setUp(() {
      mockDao = MockTokenJwtDAO();
      cubit = TokenJwtCubit(mockDao);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is TokenJwtInitial', () {
      expect(cubit.state, const TokenJwtState.initial());
    });

    group('loadToken', () {
      test('emits authenticated when token exists in storage', () async {
        mockDao._token = 'valid-jwt-token';

        await cubit.loadToken();

        expect(cubit.state, TokenJwtState.authenticated('valid-jwt-token'));
      });

      test('emits unauthenticated when token is null', () async {
        mockDao._token = null;

        await cubit.loadToken();

        expect(cubit.state, const TokenJwtState.unauthenticated());
      });

      test('emits unauthenticated when token is empty string', () async {
        mockDao._token = '';

        await cubit.loadToken();

        expect(cubit.state, const TokenJwtState.unauthenticated());
      });

      test('emits error when DAO throws exception', () async {
        mockDao.setShouldThrow(true);

        await cubit.loadToken();

        expect(cubit.state, isA<TokenJwtState>().having((s) => s is _TokenJwtStateError, 'is error', true));
      });
    });

    group('saveToken', () {
      test('saves token and emits authenticated state', () async {
        await cubit.saveToken('new-jwt-token');

        expect(cubit.state, TokenJwtState.authenticated('new-jwt-token'));
        expect(mockDao._token, equals('new-jwt-token'));
      });

      test('emits error when token is empty', () async {
        await cubit.saveToken('');

        expect(cubit.state, isA<_TokenJwtStateError>());
      });

      test('emits error when DAO throws exception', () async {
        mockDao.setShouldThrow(true);

        await cubit.saveToken('token');

        expect(cubit.state, isA<_TokenJwtStateError>());
      });
    });

    group('clearToken', () {
      test('deletes token and emits unauthenticated state', () async {
        mockDao._token = 'existing-token';

        await cubit.clearToken();

        expect(cubit.state, const TokenJwtState.unauthenticated());
        expect(mockDao._token, isNull);
      });

      test('emits error when DAO throws exception', () async {
        mockDao.setShouldThrow(true);

        await cubit.clearToken();

        expect(cubit.state, isA<_TokenJwtStateError>());
      });
    });

    group('getCurrentToken', () {
      test('returns token when state is authenticated', () {
        cubit.emit(TokenJwtState.authenticated('test-token'));
        expect(cubit.getCurrentToken(), equals('test-token'));
      });

      test('returns null when state is unauthenticated', () {
        cubit.emit(const TokenJwtState.unauthenticated());
        expect(cubit.getCurrentToken(), isNull);
      });

      test('returns null when state is initial', () {
        expect(cubit.getCurrentToken(), isNull);
      });

      test('returns null when state is error', () {
        cubit.emit(TokenJwtState.error('some error'));
        expect(cubit.getCurrentToken(), isNull);
      });
    });

    group('isAuthenticated', () {
      test('returns true when state is authenticated', () {
        cubit.emit(TokenJwtState.authenticated('token'));
        expect(cubit.isAuthenticated(), isTrue);
      });

      test('returns false when state is unauthenticated', () {
        cubit.emit(const TokenJwtState.unauthenticated());
        expect(cubit.isAuthenticated(), isFalse);
      });

      test('returns false when state is initial', () {
        expect(cubit.isAuthenticated(), isFalse);
      });

      test('returns false when state is error', () {
        cubit.emit(TokenJwtState.error('error'));
        expect(cubit.isAuthenticated(), isFalse);
      });
    });
  });
}