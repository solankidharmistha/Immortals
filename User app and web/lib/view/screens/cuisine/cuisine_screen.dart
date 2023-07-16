import 'package:efood_multivendor/controller/cuisine_controller.dart';
import 'package:efood_multivendor/controller/splash_controller.dart';
import 'package:efood_multivendor/helper/responsive_helper.dart';
import 'package:efood_multivendor/helper/route_helper.dart';
import 'package:efood_multivendor/util/dimensions.dart';
import 'package:efood_multivendor/util/styles.dart';
import 'package:efood_multivendor/view/base/custom_app_bar.dart';
import 'package:efood_multivendor/view/base/custom_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
class CuisineScreen extends StatefulWidget {
  const CuisineScreen({Key key}) : super(key: key);

  @override
  State<CuisineScreen> createState() => _CuisineScreenState();
}

class _CuisineScreenState extends State<CuisineScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<CuisineController>().getCuisineList();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'cuisines'.tr),
      body: Scrollbar(
        child: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: Dimensions.WEB_MAX_WIDTH,
              child: Column(
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      await Get.find<CuisineController>().getCuisineList();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: Dimensions.PADDING_SIZE_DEFAULT, right: Dimensions.PADDING_SIZE_DEFAULT, top: Dimensions.PADDING_SIZE_SMALL),
                      child: GetBuilder<CuisineController>(
                        builder: (cuisineController) {
                          return cuisineController.cuisineModel != null ? GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isTab(context) ? 5 : 4,
                                mainAxisSpacing: Dimensions.PADDING_SIZE_SMALL,
                                crossAxisSpacing: Dimensions.PADDING_SIZE_LARGE,
                                childAspectRatio: ResponsiveHelper.isDesktop(context) ? 1 : 0.8,
                              ),
                              shrinkWrap: true,
                              itemCount: cuisineController.cuisineModel.cuisines.length,
                              scrollDirection: Axis.vertical,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index){
                                return InkWell(
                                  onTap: (){
                                    Get.toNamed(RouteHelper.getCuisineRestaurantRoute(cuisineController.cuisineModel.cuisines[index].id, cuisineController.cuisineModel.cuisines[index].name));
                                  },
                                  child: Column(children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT),
                                        child: CustomImage(
                                          fit: BoxFit.cover,
                                          image: '${Get.find<SplashController>().configModel.baseUrls.cuisineImageUrl}/${cuisineController.cuisineModel.cuisines[index].image}',
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),

                                    Text(
                                      cuisineController.cuisineModel.cuisines[index].name,
                                      style: robotoMedium.copyWith(fontSize: 11),
                                      maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                                    ),
                                  ]),
                                );
                              }) : Center(child: CircularProgressIndicator());
                        }
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
