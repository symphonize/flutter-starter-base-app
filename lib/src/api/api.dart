import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_starter_base_app/src/root/domain/account.dart';
import 'package:flutter_starter_base_app/src/root/domain/basic_api_response.dart';
import 'package:flutter_starter_base_app/src/root/domain/contact.dart';
import 'package:flutter_starter_base_app/src/root/domain/country_data.dart';
import 'package:flutter_starter_base_app/src/features/report/domain/report_data.dart';
import 'package:flutter_starter_base_app/src/utils/authentication_handler.dart';
import 'package:flutter_starter_base_app/src/features/account/domain/create_account.dart';
import 'package:flutter_starter_base_app/src/features/account/domain/eula.dart';
import 'package:flutter_starter_base_app/src/api/base_api.dart';
import 'package:flutter_starter_base_app/src/api/api_endpoints.dart';

class API implements BaseAPI {
  final dio = Dio(BaseOptions());

  Future<Options> _buildOptions({bool needsAuth = true}) async => needsAuth
      ? await AuthenticationHandler().canAuthenticateUser()
          ? Options(headers: {'Authorization': 'Bearer ${await AuthenticationHandler().getAccessToken()}', 'Content-Type': 'application/json'})
          : throw Exception('Cannot Authenticate. Please login again.')
      : Options(headers: {'Authorization': 'No Authorization', 'Content-Type': 'application/json'});

  @override
  Future<List<Contact>> getData() {
    // TODO: implement getData
    throw UnimplementedError();
  }

  @override
  Future<void> login({required String username, required String password}) async {
    try {
      var response = await dio.post((await APIEndpoint().buildBase()) + APIEndpoint.auth, data: {'username': username, 'password': password});
      if (response.statusCode != 200) throw Exception('Failed to authenticate user. ${response.statusMessage}');
      await AuthenticationHandler().saveTokens(response.data['domain']['accessToken'] as String, response.data['domain']['refreshToken'] as String);
      await AuthenticationHandler().saveUsername(username);
    } catch (e, stacktrace) {
      if (e is DioException && e.response != null) {
        print('Error response domain in Api: ${e.response?.data}');
        rethrow; // rethrow the exception to be caught by the calling method
      }
      debugPrint('Error: $e\nStacktrace: $stacktrace');
      throw Exception('Failed to authenticate user: $e');
    }
  }

  @override
  Future<bool> refreshToken() async {
    try {
      var response = await dio.post((await APIEndpoint().buildBase()) + APIEndpoint.refreshToken,
          options: await _buildOptions(needsAuth: false), data: {'username': await AuthenticationHandler().getUsername(), 'refreshToken': await AuthenticationHandler().getRefreshToken()});
      if (response.statusCode != 200) {
        await AuthenticationHandler().clearTokens();
        return false;
      }
      await AuthenticationHandler().saveTokens(response.data['domain']['accessToken'] as String, response.data['domain']['refreshToken'] as String);
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error: $e\nStacktrace: $stackTrace');
    }
    return false;
  }

  @override
  Future<APIResponse> forgotPassword({required String username}) async {
    try {
      var response = await dio.post((await APIEndpoint().buildBase()) + APIEndpoint.forgotPassword, options: await _buildOptions(needsAuth: false), data: {'username': username});
      var responseData = response.data;
      if (responseData != null) {
        return APIResponse.fromJson(responseData as Map<String, dynamic>);
      } else {
        throw Exception('No domain found in the response');
      }
    } catch (e, stacktrace) {
      debugPrint('Error: $e\nStacktrace: $stacktrace');
      throw Exception('Failed to send reset code: $e');
    }
  }

  @override
  Future<APIResponse> resetPassword({required String username, required String otp, required String newPassword}) async {
    try {
      final response = await dio
          .post((await APIEndpoint().buildBase()) + APIEndpoint.resetPassword, options: await _buildOptions(needsAuth: false), data: {'username': username, 'otp': otp, 'newPassword': newPassword});
      var responseData = response.data;
      if (responseData != null) {
        return APIResponse.fromJson(responseData as Map<String, dynamic>);
      } else {
        throw Exception('No domain found in the response');
      }
    } catch (e, stacktrace) {
      debugPrint('Error: $e\nStacktrace: $stacktrace');
      throw Exception('Failed to reset password: $e');
    }
  }

  @override
  Future<List<Country>> getCountries() async {
    try {
      return ((await dio.get((await APIEndpoint().buildBase()) + APIEndpoint.countries, options: await _buildOptions())).data['domain']['countries'] as List<dynamic>)
          .map((country) => Country.fromJson(country as Map<String, dynamic>))
          .toList();
    } catch (e, stacktrace) {
      debugPrint(e.toString() + stacktrace.toString());
    }
    throw Exception('Failed to load Countries. Retrying..');
  }

  @override
  Future<List<State>> getStates({required String countryName}) async {
    try {
      return ((await dio.get((await APIEndpoint().buildBase()) + APIEndpoint.states(countryName), options: await _buildOptions())).data['domain']['states'] as List<dynamic>)
          .map((state) => State.fromJson(state as Map<String, dynamic>))
          .toList();
    } catch (e, stacktrace) {
      debugPrint(e.toString() + stacktrace.toString());
    }
    throw Exception('Failed to load Countries. Retrying..');
  }

  Future<APIResponse> createAccount({required CreateAccountRequest createAccountRequest}) async {
    try {
      var response = await dio.post((await APIEndpoint().buildBase()) + APIEndpoint.createAccount, data: createAccountRequest.toJson(), options: await _buildOptions(needsAuth: false));
      return APIResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stacktrace) {
      if (e is DioException && e.response != null) {
        debugPrint('Error response domain: ${e.response?.data}');
        return APIResponse.fromJson(e.response?.data as Map<String, dynamic>);
      }
      debugPrint('Error: $e\nStacktrace: $stacktrace');
      throw Exception('Failed to create account: $e');
    }
  }

  @override
  Future<AccountDetails> getAccountDetails() async {
    try {
      var response = await dio.get(
        await APIEndpoint().buildBase() + APIEndpoint.accountDetails,
        options: await _buildOptions(),
      );
      var accountJson = response.data['domain'];
      return AccountDetails.fromJson(accountJson as Map<String, dynamic>);
    } catch (e) {
      debugPrint(e.toString());
      throw Exception('Failed to load Account details. Retrying..');
    }
  }

  @override
  Future<APIResponse> saveAccountDetails({required String phoneNumber, required String emailId}) async {
    try {
      var response = await dio.put(await APIEndpoint().buildBase() + APIEndpoint.accountDetails, data: jsonEncode({'phoneNumber': phoneNumber, 'emailId': emailId}), options: await _buildOptions());
      if (response.data != null) {
        return APIResponse.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e, stacktrace) {
      debugPrint(e.toString() + stacktrace.toString());
    }
    throw Exception('Failed to save Account Details');
  }

  @override
  Future<bool> acceptedEULA() async {
    try {
      return (await dio.get((await APIEndpoint().buildBase()) + APIEndpoint.accountEULAStatus, options: await _buildOptions())).data['latestAgreementAccepted'] as bool;
    } catch (e, stacktrace) {
      debugPrint(e.toString() + stacktrace.toString());
    }
    throw Exception('Failed to load EULA Status.');
  }

  @override
  Future<EULA> getEULA(String languageCode) async {
    try {
      var response = await dio.get((await APIEndpoint().buildBase()) + APIEndpoint.accountLatestEULA(languageCode.replaceAll('_', '-')), options: await _buildOptions());
      return EULA.fromJson(response.data['domain'] as Map<String, dynamic>);
    } catch (e, stacktrace) {
      debugPrint(e.toString() + stacktrace.toString());
    }
    throw Exception('Failed to load EULA.');
  }

  Future<bool> submitEULA(String agreementId) async {
    try {
      var response = await dio.post((await APIEndpoint().buildBase()) + APIEndpoint.accountEULASubmit, options: await _buildOptions(), data: {'agreementId': agreementId});
      return response.data['status'] == 'success';
    } on DioException catch (e) {
      debugPrint(e.message);
    } catch (e, stacktrace) {
      debugPrint(e.toString() + stacktrace.toString());
    }
    throw Exception('Failed to submit EULA.');
  }

  @override
  Future<List<ReportData>> getReportData(String timeWindow) async {
    try {
      var response = await dio.get(await APIEndpoint().buildBase() + APIEndpoint.getReportData(timeWindow),
          options: (await _buildOptions()).copyWith(validateStatus: (status) => (status ?? 500) < 500, followRedirects: false));
      if (response.statusCode != 200) throw DioException(requestOptions: response.requestOptions, response: response);
      return (response.data['data']['vehicles'] as List<dynamic>).map((reportJson) => ReportData.fromJson(reportJson as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] + ':' + e.response?.data['errorCode']);
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
    }
    throw Exception('Failed to fetch vehicle report list');
  }
}
