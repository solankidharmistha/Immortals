import 'package:efood_multivendor_restaurant/data/model/response/expense_model.dart';
import 'package:efood_multivendor_restaurant/helper/date_converter.dart';
import 'package:efood_multivendor_restaurant/helper/price_converter.dart';
import 'package:efood_multivendor_restaurant/util/dimensions.dart';
import 'package:efood_multivendor_restaurant/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
class ExpenseCard extends StatelessWidget {
  final Expense expense;
  const ExpenseCard({Key key, @required this.expense}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
          boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 800 : 200], offset: Offset(0, 5), blurRadius: 10)]
      ),
      padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
      margin: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Text('${'order_id'.tr}: #${expense.orderId}', style: robotoMedium),
        SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),

        Divider(),

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            DateConverter.dateTimeStringToDateTime(expense.createdAt),
            style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor),
          ),
          Text('amount'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor)),
        ]),
        SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Text('expense_type'.tr + ' - ', style: robotoMedium.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL)),
            Text(expense.type.tr, style: robotoMedium.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Colors.blue)),
          ]),
          Text(PriceConverter.convertPrice(expense.amount), style: robotoBold.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE,)),
        ]),
      ]),
    );
  }
}
