import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tix/core/bloc/token_jwt/token_jwt_cubit.dart';
import 'package:mobile_tix/core/bloc/token_jwt/token_jwt_state.dart';
import 'package:mobile_tix/core/data/dao/token_jwt_dao.dart';
import 'package:mobile_tix/core/services/token_refresh_service.dart';

// Manual mock implementation for TokenRefreshService
class MockTokenRefreshService extends TokenRefreshService {
  String? lastScheduledToken;
  bool cancelCalled = false;

  @override
  void scheduleNextRefresh(String token, {Duration? leadTime}) {
    lastScheduledToken = token;
  }

  @override
  void cancel() {
    cancelCalled = true;
    super.cancel();
  }
}

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

        // Error state adalah subclass private _TokenJwtStateError,
        // tidak bisa di-referensikan langsung di file test.
        // Cek: state bukan initial, authenticated, atau unauthenticated.
        expect(cubit.state, isNot(const TokenJwtState.initial()));
        expect(cubit.state, isNot(isA<TokenJwtStateAuthenticated>()));
        expect(cubit.state, isNot(const TokenJwtState.unauthenticated()));
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

        // State error → tidak salah-satu dari tiga state valid di atas
        expect(cubit.state, isNot(const TokenJwtState.initial()));
        expect(cubit.state, isNot(isA<TokenJwtStateAuthenticated>()));
        expect(cubit.state, isNot(const TokenJwtState.unauthenticated()));
      });

      test('emits error when DAO throws exception', () async {
        mockDao.setShouldThrow(true);

        await cubit.saveToken('token');

        // State error → tidak salah-satu dari tiga state valid di atas
        expect(cubit.state, isNot(const TokenJwtState.initial()));
        expect(cubit.state, isNot(isA<TokenJwtStateAuthenticated>()));
        expect(cubit.state, isNot(const TokenJwtState.unauthenticated()));
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

        // State error → tidak salah-satu dari tiga state valid di atas
        expect(cubit.state, isNot(const TokenJwtState.initial()));
        expect(cubit.state, isNot(isA<TokenJwtStateAuthenticated>()));
        expect(cubit.state, isNot(const TokenJwtState.unauthenticated()));
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

    group('TokenRefreshService integration', () {
      test('schedules refresh on loadToken when token exists', () async {
        final mockRefresh = MockTokenRefreshService();
        final cubitWithRefresh = TokenJwtCubit(mockDao, mockRefresh);
        mockDao._token = 'my-token';

        await cubitWithRefresh.loadToken();

        expect(mockRefresh.lastScheduledToken, equals('my-token'));
        cubitWithRefresh.close();
      });

      test('schedules refresh on saveToken', () async {
        final mockRefresh = MockTokenRefreshService();
        final cubitWithRefresh = TokenJwtCubit(mockDao, mockRefresh);

        await cubitWithRefresh.saveToken('saved-token');

        expect(mockRefresh.lastScheduledToken, equals('saved-token'));
        cubitWithRefresh.close();
      });

      test('cancels refresh on clearToken', () async {
        final mockRefresh = MockTokenRefreshService();
        final cubitWithRefresh = TokenJwtCubit(mockDao, mockRefresh);

        await cubitWithRefresh.clearToken();

        expect(mockRefresh.cancelCalled, isTrue);
        cubitWithRefresh.close();
      });
    });
  });
}