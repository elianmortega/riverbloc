import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverbloc/riverbloc.dart';

import 'helpers/helpers.dart';

void main() {
  group('AutoDispose Provider names', () {
    test('AutoDisposeBlocProvider.notifier with no name', () {
      final counterBlocProvider = AutoDisposeBlocProvider<CounterBloc, int>(
        (ref) => CounterBloc(0),
      );
      expect(counterBlocProvider.notifier.name, isNull);
      expect(counterBlocProvider.stream.name, isNull);

      final counterCubitProvider = BlocProvider.autoDispose<CounterCubit, int>(
        (ref) => CounterCubit(0),
      );
      expect(counterCubitProvider.notifier.name, isNull);
      expect(counterCubitProvider.stream.name, isNull);
    });

    test('BlocProvider.notifier with name', () {
      final counterBlocProvider = BlocProvider<CounterBloc, int>(
        (ref) => CounterBloc(0),
        name: 'counterBloc',
      );
      expect(counterBlocProvider.notifier.name, 'counterBloc.notifier');
      expect(counterBlocProvider.stream.name, 'counterBloc.stream');

      final counterCubitProvider = BlocProvider.autoDispose<CounterCubit, int>(
        (ref) => CounterCubit(0),
        name: 'counterCubit',
      );
      expect(counterCubitProvider.notifier.name, 'counterCubit.notifier');
      expect(counterCubitProvider.stream.name, 'counterCubit.stream');
    });
  });

  group('AlwaysAlive vs AutoDispose', () {
    test('BlocProvider', () async {
      var closeCounter1 = 0;
      var closeCounter2 = 0;
      void onClose1() => closeCounter1++;
      void onClose2() => closeCounter2++;

      final listener1 = Listener<int>();
      final listener2 = Listener<int>();

      final counterProvider1 = BlocProvider<CounterCubit, int>(
        (ref) => CounterCubit(0, onClose: onClose1),
      );
      final counterProvider2 = BlocProvider.autoDispose<CounterCubit, int>(
        (ref) => CounterCubit(0, onClose: onClose2),
      );

      final container = ProviderContainer();

      final sub1 = container.listen<int>(counterProvider1, listener1);

      final sub2 = container.listen<int>(counterProvider2, listener2);

      expect(sub1.read(), 0);
      expect(sub2.read(), 0);

      container.read(counterProvider1.notifier).increment();
      container.read(counterProvider2.notifier).increment();
      await Future(() {});
      expect(sub1.read(), 1);
      verify(() => listener1(1)).called(1);
      expect(sub2.read(), 1);
      verify(() => listener2(1)).called(1);

      verifyNoMoreInteractions(listener1);
      verifyNoMoreInteractions(listener2);

      expect(closeCounter1, 0);
      expect(closeCounter2, 0);
      sub1.close();
      sub2.close();
      await Future(() {});
      expect(closeCounter1, 0);
      expect(closeCounter2, 1);

      expect(container.read(counterProvider1), 1);
      expect(container.read(counterProvider2), 0);

      await Future(() {});
      expect(closeCounter1, 0);
      expect(closeCounter2, 2);

      container.read(counterProvider1.notifier).increment();
      container.read(counterProvider2.notifier).increment();
      await Future(() {});
      expect(closeCounter1, 0);
      expect(closeCounter2, 3);

      expect(container.read(counterProvider1), 2);
      expect(container.read(counterProvider2), 0);

      await Future(() {});
      expect(closeCounter1, 0);
      expect(closeCounter2, 4);
    });

    test('BlocProvider.stream', () async {
      var closeCounter1 = 0;
      var closeCounter2 = 0;
      void onClose1() => closeCounter1++;
      void onClose2() => closeCounter2++;

      final listener1 = Listener<AsyncValue<int>>();
      final listener2 = Listener<AsyncValue<int>>();

      final counterProvider1 = BlocProvider<CounterCubit, int>(
        (ref) => CounterCubit(0, onClose: onClose1),
      );
      final counterProvider2 = BlocProvider.autoDispose<CounterCubit, int>(
        (ref) => CounterCubit(0, onClose: onClose2),
      );

      final container = ProviderContainer();

      final sub1 = container.listen<AsyncValue<int>>(
        counterProvider1.stream,
        listener1,
      );

      final sub2 = container.listen<AsyncValue<int>>(
        counterProvider2.stream,
        listener2,
      );

      expect(sub1.read(), equals(const AsyncLoading()));
      expect(sub2.read(), equals(const AsyncLoading()));

      container.read(counterProvider1.notifier).increment();
      container.read(counterProvider2.notifier).increment();
      await Future(() {});
      expect(sub1.read(), const AsyncData(1));
      verify(() => listener1(const AsyncData(1))).called(1);
      expect(sub2.read(), const AsyncData(1));
      verify(() => listener2(const AsyncData(1))).called(1);

      container.read(counterProvider1.notifier).increment();
      container.read(counterProvider2.notifier).increment();
      await Future(() {});
      expect(sub1.read(), const AsyncData(2));
      verify(() => listener1(const AsyncData(2))).called(1);
      expect(sub2.read(), const AsyncData(2));
      verify(() => listener2(const AsyncData(2))).called(1);

      verifyNoMoreInteractions(listener1);
      verifyNoMoreInteractions(listener2);

      expect(closeCounter1, 0);
      expect(closeCounter2, 0);
      sub1.close();
      sub2.close();
      await Future(() {});
      expect(closeCounter1, 0);
      expect(closeCounter2, 1);

      expect(
        container.read(counterProvider1.stream),
        const AsyncData(2),
      );
      expect(
        container.read(counterProvider2.stream),
        const AsyncLoading(),
      );

      await Future(() {});
      expect(closeCounter1, 0);
      expect(closeCounter2, 2);

      container.read(counterProvider1.notifier).increment();
      container.read(counterProvider2.notifier).increment();
      await Future(() {});
      expect(closeCounter1, 0);
      expect(closeCounter2, 3);

      expect(
        container.read(counterProvider1.stream),
        const AsyncData(3),
      );
      expect(
        container.read(counterProvider2.stream),
        const AsyncLoading(),
      );

      await Future(() {});
      expect(closeCounter1, 0);
      expect(closeCounter2, 4);
    });
  });

  group('AutoDisposeBlocProvider override', () {
    test('Override with provider', () async {
      var closeCounter1 = 0;
      var closeCounter2 = 0;
      void onClose1() => closeCounter1++;
      void onClose2() => closeCounter2++;
      final counterProvider1 = AutoDisposeBlocProvider<CounterCubit, int>(
        (ref) => CounterCubit(0, onClose: onClose1),
      );
      final counterProvider2 = BlocProvider.autoDispose<CounterCubit, int>(
        (ref) => CounterCubit(5, onClose: onClose2),
      );

      final container = ProviderContainer(
        overrides: [
          counterProvider1.overrideWithProvider(counterProvider2),
        ],
      );

      final listener = Listener<int>();
      final sub = container.listen<int>(counterProvider1, listener);

      expect(sub.read(), 5);
      container.read(counterProvider1.notifier).increment();
      await Future(() {});
      expect(sub.read(), 6);

      expect(closeCounter1, 0);
      expect(closeCounter2, 0);
      sub.close();
      await Future(() {});
      expect(closeCounter1, 0);
      expect(closeCounter2, 1);
    });
  });

  group('BlocProvider.bloc', () {
    final counterCubitProvider = BlocProvider.autoDispose<CounterCubit, int>(
      (ref) => CounterCubit(0),
    );

    test('BlocProvider.bloc get BlocBase Object', () {
      final container = ProviderContainer();
      final counterCubit = container.read(counterCubitProvider.bloc);

      expect(counterCubit, isA<BlocBase>());
    });

    test('BlocProvider.bloc equals BlocProvider.notifier', () {
      final container = ProviderContainer();
      final bloc = container.read(counterCubitProvider.bloc);
      final notifier = container.read(counterCubitProvider.notifier);

      expect(bloc, equals(notifier));
    });
  });
}
