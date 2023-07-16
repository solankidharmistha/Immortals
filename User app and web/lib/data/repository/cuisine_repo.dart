import 'package:efood_multivendor/data/api/api_client.dart';
import 'package:efood_multivendor/util/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get_connect/http/src/response/response.dart';

class CuisineRepo {
  final ApiClient apiClient;
  CuisineRepo({@required this.apiClient});

  Future<Response> getCuisineList() async {
    return await apiClient.getData(AppConstants.CUISINE_URI);
  }

  Future<Response> getCuisineRestaurantList(int offset, int cuisineId) async {
    return await apiClient.getData('${AppConstants.CUISINE_RESTAURANT_URI}?cuisine_id=$cuisineId&offset=$offset&limit=10');
  }

}