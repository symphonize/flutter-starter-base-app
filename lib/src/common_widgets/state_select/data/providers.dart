import 'package:flutter_starter_base_app/src/api/api_facade.dart';
import 'package:flutter_starter_base_app/src/root/domain/country_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'providers.g.dart';

@riverpod
Future<List<State>> fetchStateList(FetchStateListRef ref, {required String countryName}) async =>
    (await APIFacade().getApi()).getStates(countryName: countryName);