import 'package:efood_multivendor_restaurant/data/api/api_client.dart';
import 'package:efood_multivendor_restaurant/util/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExpenseRepo {
  final ApiClient apiClient;

  ExpenseRepo({@required this.apiClient});

  Future<Response> getExpenseList({@required int offset, @required int restaurantId, @required String from, @required String to,  @required String searchText}) async {
    print('---------------${searchText == null}');
    return apiClient.getData('${AppConstants.EXPENSE_LIST_URI}?limit=10&offset=$offset&restaurant_id=$restaurantId&from=$from&to=$to&search=${searchText == null ? '' : searchText}');
  }
}