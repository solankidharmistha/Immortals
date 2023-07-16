import 'dart:io';

import 'package:efood_multivendor_restaurant/controller/auth_controller.dart';
import 'package:efood_multivendor_restaurant/controller/restaurant_controller.dart';
import 'package:efood_multivendor_restaurant/controller/splash_controller.dart';
import 'package:efood_multivendor_restaurant/data/model/response/profile_model.dart';
import 'package:efood_multivendor_restaurant/util/dimensions.dart';
import 'package:efood_multivendor_restaurant/util/images.dart';
import 'package:efood_multivendor_restaurant/util/styles.dart';
import 'package:efood_multivendor_restaurant/view/base/custom_app_bar.dart';
import 'package:efood_multivendor_restaurant/view/base/custom_button.dart';
import 'package:efood_multivendor_restaurant/view/base/custom_snackbar.dart';
import 'package:efood_multivendor_restaurant/view/base/my_text_field.dart';
import 'package:efood_multivendor_restaurant/view/base/switch_button.dart';
import 'package:efood_multivendor_restaurant/view/screens/restaurant/widget/daily_time_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RestaurantSettingsScreen extends StatefulWidget {
  final Restaurant restaurant;
  RestaurantSettingsScreen({@required this.restaurant});

  @override
  State<RestaurantSettingsScreen> createState() => _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _orderAmountController = TextEditingController();
  final TextEditingController _minimumChargeController = TextEditingController();
  final TextEditingController _maximumChargeController = TextEditingController();
  final TextEditingController _perKmChargeController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  TextEditingController _c = TextEditingController();
  final FocusNode _nameNode = FocusNode();
  final FocusNode _contactNode = FocusNode();
  final FocusNode _addressNode = FocusNode();
  final FocusNode _orderAmountNode = FocusNode();
  final FocusNode _minimumChargeNode = FocusNode();
  final FocusNode _maximumChargeNode = FocusNode();
  final FocusNode _perKmChargeNode = FocusNode();
  Restaurant _restaurant;

  @override
  void initState() {
    super.initState();

    Get.find<RestaurantController>().initRestaurantData(widget.restaurant);

    _nameController.text = widget.restaurant.name;
    _contactController.text = widget.restaurant.phone;
    _addressController.text = widget.restaurant.address;
    _orderAmountController.text = widget.restaurant.minimumOrder.toString();
    _minimumChargeController.text = widget.restaurant.minimumShippingCharge != null ? widget.restaurant.minimumShippingCharge.toString() : '';
    _maximumChargeController.text = widget.restaurant.maximumShippingCharge != null ? widget.restaurant.maximumShippingCharge.toString() : '';
    _perKmChargeController.text = widget.restaurant.perKmShippingCharge != null ? widget.restaurant.perKmShippingCharge.toString() : '';
    _gstController.text = widget.restaurant.gstCode;
    _restaurant = widget.restaurant;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'restaurant_settings'.tr),
      body: GetBuilder<RestaurantController>(builder: (restController) {

        List<int> _cuisines = [];
        if(restController.cuisineModel != null) {
          for(int index=0; index<restController.cuisineModel.cuisines.length; index++) {
            if(restController.cuisineModel.cuisines[index].status == 1 && !restController.selectedCuisines.contains(index)) {
              _cuisines.add(index);
            }
          }
        }
        return Column(children: [

          Expanded(child: SingleChildScrollView(
            padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
            physics: BouncingScrollPhysics(),
            child: Column(children: [

              Text(
                'logo'.tr,
                style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor),
              ),
              SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
              Align(alignment: Alignment.center, child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                  child: restController.pickedLogo != null ? GetPlatform.isWeb ? Image.network(
                    restController.pickedLogo.path, width: 150, height: 120, fit: BoxFit.cover,
                  ) : Image.file(
                    File(restController.pickedLogo.path), width: 150, height: 120, fit: BoxFit.cover,
                  ) : FadeInImage.assetNetwork(
                    placeholder: Images.placeholder,
                    image: '${Get.find<SplashController>().configModel.baseUrls.restaurantImageUrl}/${widget.restaurant.logo}',
                    height: 120, width: 150, fit: BoxFit.cover,
                    imageErrorBuilder: (c, o, s) => Image.asset(Images.placeholder, height: 120, width: 150, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0, top: 0, left: 0,
                  child: InkWell(
                    onTap: () => restController.pickImage(true, false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                        border: Border.all(width: 1, color: Theme.of(context).primaryColor),
                      ),
                      child: Container(
                        margin: EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          border: Border.all(width: 2, color: Colors.white),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ])),
              SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

              MyTextField(
                hintText: 'restaurant_name'.tr,
                controller: _nameController,
                focusNode: _nameNode,
                nextFocus: _contactNode,
                capitalization: TextCapitalization.words,
                inputType: TextInputType.name,
              ),
              SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

              MyTextField(
                hintText: 'contact_number'.tr,
                controller: _contactController,
                focusNode: _contactNode,
                nextFocus: _addressNode,
                inputType: TextInputType.phone,
              ),
              SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

              MyTextField(
                hintText: 'address'.tr,
                controller: _addressController,
                focusNode: _addressNode,
                nextFocus: _orderAmountNode,
                inputType: TextInputType.streetAddress,
              ),
              SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

              Row(children: [
                Expanded(
                  child: MyTextField(
                    hintText: 'minimum_order_amount'.tr,
                    controller: _orderAmountController,
                    focusNode: _orderAmountNode,
                    nextFocus: _restaurant.selfDeliverySystem == 1 ? _perKmChargeNode : null,
                    inputAction: _restaurant.selfDeliverySystem == 0 ? null : TextInputAction.done,
                    inputType: TextInputType.number,
                    isAmount: true,
                  ),
                ),
                SizedBox(width: _restaurant.selfDeliverySystem == 1 ? Dimensions.PADDING_SIZE_SMALL : 0),

                _restaurant.selfDeliverySystem == 1 ? Expanded(
                  child: MyTextField(
                    hintText: 'per_km_delivery_charge'.tr,
                    controller: _perKmChargeController,
                    focusNode: _restaurant.selfDeliverySystem == 1 ? _perKmChargeNode : null,
                    nextFocus: _restaurant.selfDeliverySystem == 1 ? _minimumChargeNode : null,
                    inputType: TextInputType.number,
                    isAmount: true,
                  ),
                ) : SizedBox(),
              ]),
              SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

              _restaurant.selfDeliverySystem == 1 ? Row(children: [
                Expanded(child: MyTextField(
                  hintText: 'minimum_delivery_charge'.tr,
                  controller: _minimumChargeController,
                  focusNode: _minimumChargeNode,
                  nextFocus: _maximumChargeNode,
                  inputType: TextInputType.number,
                  isAmount: true,
                )),
                SizedBox(width: Dimensions.PADDING_SIZE_SMALL),

                Expanded(child: MyTextField(
                  hintText: 'maximum_delivery_charge'.tr,
                  controller: _maximumChargeController,
                  focusNode: _maximumChargeNode,
                  inputAction: TextInputAction.done,
                  inputType: TextInputType.number,
                  isAmount: true,
                )),
              ]) : SizedBox(),
              SizedBox(height: _restaurant.selfDeliverySystem == 1 ? Dimensions.PADDING_SIZE_LARGE : 0),

              Column(children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'cuisines'.tr,
                    style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL),
                  ),
                ),
                SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),

                Autocomplete<int>(
                  optionsBuilder: (TextEditingValue value) {
                    if(value.text.isEmpty) {
                      return Iterable<int>.empty();
                    }else {
                      return _cuisines.where((cuisine) => restController.cuisineModel.cuisines[cuisine].name.toLowerCase().contains(value.text.toLowerCase()));
                    }
                  },
                  fieldViewBuilder: (context, controller, node, onComplete) {
                    _c = controller;
                    return Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                        // boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 800 : 200], spreadRadius: 2, blurRadius: 5, offset: Offset(0, 5))],
                      ),
                      child: TextField(
                        controller: controller,
                        focusNode: node,
                        onEditingComplete: () {
                          onComplete();
                          controller.text = '';
                        },
                        decoration: InputDecoration(
                          hintText: 'cuisines'.tr,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL), borderSide: BorderSide.none),
                        ),
                      ),
                    );
                  },
                  displayStringForOption: (value) => restController.cuisineModel.cuisines[value].name,
                  onSelected: (int value) {
                    _c.text = '';
                    restController.setSelectedCuisineIndex(value, true);
                  },
                ),

                SizedBox(height: restController.selectedCuisines.length > 0 ? Dimensions.PADDING_SIZE_SMALL : 0),
                SizedBox(
                  height: restController.selectedCuisines.length > 0 ? 40 : 0,
                  child: ListView.builder(
                    itemCount: restController.selectedCuisines.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: EdgeInsets.only(left: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                        margin: EdgeInsets.only(right: Dimensions.PADDING_SIZE_SMALL),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                        ),
                        child: Row(children: [
                          Text(
                            restController.cuisineModel.cuisines[restController.selectedCuisines[index]].name,
                            style: robotoRegular.copyWith(color: Theme.of(context).cardColor),
                          ),
                          InkWell(
                            onTap: () => restController.removeCuisine(index),
                            child: Padding(
                              padding: EdgeInsets.all(Dimensions.PADDING_SIZE_EXTRA_SMALL),
                              child: Icon(Icons.close, size: 15, color: Theme.of(context).cardColor),
                            ),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              ]),
              SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

              Get.find<SplashController>().configModel.toggleVegNonVeg ? Align(alignment: Alignment.centerLeft, child: Text(
                'food_type'.tr,
                style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor),
              )) : SizedBox(),
              Get.find<SplashController>().configModel.toggleVegNonVeg ? Row(children: [
                Expanded(child: InkWell(
                  onTap: () => restController.setRestVeg(!restController.isRestVeg, true),
                  child: Row(children: [
                    Checkbox(
                      value: restController.isRestVeg,
                      onChanged: (bool isActive) => restController.setRestVeg(isActive, true),
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    Text('veg'.tr),
                  ]),
                )),
                SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                Expanded(child: InkWell(
                  onTap: () => restController.setRestNonVeg(!restController.isRestNonVeg, true),
                  child: Row(children: [
                    Checkbox(
                      value: restController.isRestNonVeg,
                      onChanged: (bool isActive) => restController.setRestNonVeg(isActive, true),
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    Text('non_veg'.tr),
                  ]),
                )),
              ]) : SizedBox(),
              SizedBox(height: Get.find<SplashController>().configModel.toggleVegNonVeg ? Dimensions.PADDING_SIZE_LARGE : 0),

              Row(children: [
                Expanded(child: Text(
                  'gst'.tr,
                  style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor),
                )),
                Switch(
                  value: restController.isGstEnabled,
                  activeColor: Theme.of(context).primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (bool isActive) => restController.toggleGst(),
                ),
              ]),
              MyTextField(
                hintText: 'gst'.tr,
                controller: _gstController,
                inputAction: TextInputAction.done,
                title: false,
                isEnabled: restController.isGstEnabled,
              ),
              SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

              Align(alignment: Alignment.centerLeft, child: Text(
                'daily_schedule_time'.tr,
                style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor),
              )),
              SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
              ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: 7,
                itemBuilder: (context, index) {
                  return DailyTimeWidget(weekDay: index);
                },
              ),
              SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

              Get.find<SplashController>().configModel.scheduleOrder ? SwitchButton(icon: Icons.alarm_add, title: 'schedule_order'.tr, isButtonActive: widget.restaurant.scheduleOrder, onTap: () {
                _restaurant.scheduleOrder = !_restaurant.scheduleOrder;
              }) : SizedBox(),
              SizedBox(height: Get.find<SplashController>().configModel.scheduleOrder ? Dimensions.PADDING_SIZE_SMALL : 0),

              SwitchButton(icon: Icons.delivery_dining, title: 'delivery'.tr, isButtonActive: widget.restaurant.delivery, onTap: () {
                _restaurant.delivery = !_restaurant.delivery;
              }),
              SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

              SwitchButton(icon: Icons.house_siding, title: 'take_away'.tr, isButtonActive: widget.restaurant.takeAway, onTap: () {
                _restaurant.takeAway = !_restaurant.takeAway;
              }),
              SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                  child: restController.pickedCover != null ? GetPlatform.isWeb ? Image.network(
                    restController.pickedCover.path, width: context.width, height: 170, fit: BoxFit.cover,
                  ) : Image.file(
                    File(restController.pickedCover.path), width: context.width, height: 170, fit: BoxFit.cover,
                  ) : FadeInImage.assetNetwork(
                    placeholder: Images.restaurant_cover,
                    image: '${Get.find<SplashController>().configModel.baseUrls.restaurantCoverPhotoUrl}/${widget.restaurant.coverPhoto}',
                    height: 170, width: context.width, fit: BoxFit.cover,
                    imageErrorBuilder: (c, o, s) => Image.asset(Images.placeholder, height: 170, width: context.width, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0, top: 0, left: 0,
                  child: InkWell(
                    onTap: () => restController.pickImage(false, false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                        border: Border.all(width: 1, color: Theme.of(context).primaryColor),
                      ),
                      child: Container(
                        margin: EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          border: Border.all(width: 3, color: Colors.white),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 50),
                      ),
                    ),
                  ),
                ),
              ]),

            ]),
          )),

          !restController.isLoading ? CustomButton(
            margin: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
            onPressed: () {
              String _name = _nameController.text.trim();
              String _contact = _contactController.text.trim();
              String _address = _addressController.text.trim();
              String _minimumOrder = _orderAmountController.text.trim();
              String _minimumFee = _minimumChargeController.text.trim();
              String _perKmFee = _perKmChargeController.text.trim();
              String _gstCode = _gstController.text.trim();
              String _maximumFee = _maximumChargeController.text.trim();
              if(_name.isEmpty) {
                showCustomSnackBar('enter_your_restaurant_name'.tr);
              }else if(_contact.isEmpty) {
                showCustomSnackBar('enter_restaurant_contact_number'.tr);
              }else if(_address.isEmpty) {
                showCustomSnackBar('enter_restaurant_address'.tr);
              }else if(_minimumOrder.isEmpty) {
                showCustomSnackBar('enter_minimum_order_amount'.tr);
              }else if(_restaurant.selfDeliverySystem == 1 && _perKmFee.isNotEmpty && _minimumFee.isEmpty && _maximumFee.isNotEmpty) {
                showCustomSnackBar('enter_minimum_delivery_fee'.tr);
              }else if(_restaurant.selfDeliverySystem == 1 && _minimumFee.isNotEmpty && _perKmFee.isEmpty && _maximumFee.isNotEmpty) {
                showCustomSnackBar('enter_per_km_delivery_fee'.tr);
              }else if(_restaurant.selfDeliverySystem == 1 && _minimumFee.isNotEmpty && _maximumFee.isNotEmpty && (double.parse(_minimumFee) > double.parse(_maximumFee))) {
                showCustomSnackBar('minimum_charge_can_not_be_more_then_maximum_charge'.tr);
              }else if(!restController.isRestVeg && !restController.isRestNonVeg){
                showCustomSnackBar('select_at_least_one_food_type'.tr);
              }else if(restController.isGstEnabled && _gstCode.isEmpty) {
                showCustomSnackBar('enter_gst_code'.tr);
              }else if(_restaurant.selfDeliverySystem == 1 && _minimumFee.isNotEmpty && _perKmFee.isNotEmpty && _maximumFee.isEmpty) {
                showCustomSnackBar('enter_maximum_delivery_fee'.tr);
              }else {
                List<String> cuisines = [];
                restController.selectedCuisines.forEach((index) {
                  cuisines.add(restController.cuisineModel.cuisines[index].id.toString());
                });
                print('-----cuisines------: $cuisines');

                _restaurant.name = _name;
                _restaurant.phone = _contact;
                _restaurant.address = _address;
                _restaurant.minimumOrder = double.parse(_minimumOrder);
                _restaurant.gstStatus = restController.isGstEnabled;
                _restaurant.gstCode = _gstCode;
                _restaurant.minimumShippingCharge = _minimumFee.isNotEmpty ? double.parse(_minimumFee) : null;
                _restaurant.maximumShippingCharge = _maximumFee.isNotEmpty ? double.parse(_maximumFee) : null;
                _restaurant.perKmShippingCharge = _perKmFee.isNotEmpty ? double.parse(_perKmFee) : null;
                _restaurant.veg = restController.isRestVeg ? 1 : 0;
                _restaurant.nonVeg = restController.isRestNonVeg ? 1 : 0;
                restController.updateRestaurant(_restaurant, cuisines, Get.find<AuthController>().getUserToken());
              }
            },
            buttonText: 'update'.tr,
          ) : Center(child: CircularProgressIndicator()),

        ]);
      }),
    );
  }
}
