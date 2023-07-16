import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:efood_multivendor_restaurant/controller/auth_controller.dart';
import 'package:efood_multivendor_restaurant/controller/splash_controller.dart';
import 'package:efood_multivendor_restaurant/data/model/body/bluetoothPrinterBody.dart';
import 'package:efood_multivendor_restaurant/data/model/response/order_details_model.dart';
import 'package:efood_multivendor_restaurant/data/model/response/order_model.dart';
import 'package:efood_multivendor_restaurant/data/model/response/profile_model.dart';
import 'package:efood_multivendor_restaurant/helper/date_converter.dart';
import 'package:efood_multivendor_restaurant/util/dimensions.dart';
import 'package:efood_multivendor_restaurant/util/styles.dart';
import 'package:efood_multivendor_restaurant/view/base/custom_button.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as i;
import 'package:screenshot/screenshot.dart';

class InVoicePrintScreen extends StatefulWidget {
  final OrderModel order;
  final List<OrderDetailsModel> orderDetails;
  const InVoicePrintScreen({@required this.order, @required this.orderDetails});

  @override
  State<InVoicePrintScreen> createState() => _InVoicePrintScreenState();
}

class _InVoicePrintScreenState extends State<InVoicePrintScreen> {
  PrinterType _defaultPrinterType = PrinterType.bluetooth;
  bool _isBle = false;
  PrinterManager _printerManager = PrinterManager.instance;
  List<BluetoothPrinter> _devices = <BluetoothPrinter>[];
  StreamSubscription<PrinterDevice> _subscription;
  StreamSubscription<BTStatus> _subscriptionBtStatus;
  BTStatus _currentStatus = BTStatus.none;
  List<int> pendingTask;
  String _ipAddress = '';
  String _port = '9100';
  bool _paper80MM = true;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  BluetoothPrinter _selectedPrinter;
  bool _searchingMode = true;

  @override
  void initState() {
    if (Platform.isWindows) _defaultPrinterType = PrinterType.usb;
    super.initState();
    _portController.text = _port;
    _scan();

    // subscription to listen change status of bluetooth connection
    _subscriptionBtStatus = PrinterManager.instance.stateBluetooth.listen((status) {
      log(' ----------------- status bt $status ------------------ ');
      _currentStatus = status;

      if (status == BTStatus.connected && pendingTask != null) {
        if (Platform.isAndroid) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            PrinterManager.instance.send(type: PrinterType.bluetooth, bytes: pendingTask);
            pendingTask = null;
          });
        } else if (Platform.isIOS) {
          PrinterManager.instance.send(type: PrinterType.bluetooth, bytes: pendingTask);
          pendingTask = null;
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscriptionBtStatus?.cancel();
    _portController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  // method to scan devices according PrinterType
  void _scan() {
    _devices.clear();
    _subscription = _printerManager.discovery(type: _defaultPrinterType, isBle: _isBle).listen((device) {
      _devices.add(BluetoothPrinter(
        deviceName: device.name,
        address: device.address,
        isBle: _isBle,
        vendorId: device.vendorId,
        productId: device.productId,
        typePrinter: _defaultPrinterType,
      ));
      setState(() {});
    });
  }

  void _setPort(String value) {
    if (value.isEmpty) value = '9100';
    _port = value;
    var device = BluetoothPrinter(
      deviceName: value,
      address: _ipAddress,
      port: _port,
      typePrinter: PrinterType.network,
      state: false,
    );
    _selectDevice(device);
  }

  void _setIpAddress(String value) {
    _ipAddress = value;
    BluetoothPrinter _device = BluetoothPrinter(
      deviceName: value,
      address: _ipAddress,
      port: _port,
      typePrinter: PrinterType.network,
      state: false,
    );
    _selectDevice(_device);
  }

  void _selectDevice(BluetoothPrinter device) async {
    if (_selectedPrinter != null) {
      if ((device.address != _selectedPrinter.address) || (device.typePrinter == PrinterType.usb && _selectedPrinter.vendorId != device.vendorId)) {
        await PrinterManager.instance.disconnect(type: _selectedPrinter.typePrinter);
      }
    }

    _selectedPrinter = device;
    setState(() {});
  }

  Future _printReceipt(i.Image image) async {
    CapabilityProfile _profile = await CapabilityProfile.load();
    Generator _generator = Generator(_paper80MM ? PaperSize.mm80 : PaperSize.mm58, _profile);
    List<int> _bytes = [];
    _bytes += _generator.image(image);
    _printEscPos(_bytes, _generator);
  }

  /// print ticket
  void _printEscPos(List<int> bytes, Generator generator) async {
    if (_selectedPrinter == null) return;
    var bluetoothPrinter = _selectedPrinter;

    switch (bluetoothPrinter.typePrinter) {
      case PrinterType.usb:
        bytes += generator.feed(2);
        bytes += generator.cut();
        await _printerManager.connect(
          type: bluetoothPrinter.typePrinter,
          model: UsbPrinterInput(
            name: bluetoothPrinter.deviceName,
            productId: bluetoothPrinter.productId,
            vendorId: bluetoothPrinter.vendorId,
          ),
        );
        break;
      case PrinterType.bluetooth:
        bytes += generator.cut();
        await _printerManager.connect(
          type: bluetoothPrinter.typePrinter,
          model: BluetoothPrinterInput(
            name: bluetoothPrinter.deviceName,
            address: bluetoothPrinter.address,
            isBle: bluetoothPrinter.isBle ?? false,
          ),
        );
        pendingTask = null;
        if (Platform.isIOS || Platform.isAndroid) pendingTask = bytes;
        break;
      case PrinterType.network:
        bytes += generator.feed(2);
        bytes += generator.cut();
        await _printerManager.connect(
          type: bluetoothPrinter.typePrinter,
          model: TcpPrinterInput(ipAddress: bluetoothPrinter.address),
        );
        break;
      default:
    }
    if (bluetoothPrinter.typePrinter == PrinterType.bluetooth) {
      try{
        print('------$_currentStatus');
        _printerManager.send(type: bluetoothPrinter.typePrinter, bytes: bytes);
        pendingTask = null;
      }catch(e) {}
    } else {
      _printerManager.send(type: bluetoothPrinter.typePrinter, bytes: bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _searchingMode ? SingleChildScrollView(
      padding: EdgeInsets.all(Dimensions.FONT_SIZE_LARGE),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Text('paper_size'.tr, style: robotoMedium),
          Row(children: [
            Expanded(child: RadioListTile(
              title: Text('80_mm'.tr),
              groupValue: _paper80MM,
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: true,
              onChanged: (bool value) {
                _paper80MM = true;
                setState(() {});
              },
            )),
            Expanded(child: RadioListTile(
              title: Text('58_mm'.tr),
              groupValue: _paper80MM,
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: false,
              onChanged: (bool value) {
                _paper80MM = false;
                setState(() {});
              },
            )),
          ]),
          SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

          ListView.builder(
            itemCount: _devices.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_SMALL),
                child: InkWell(
                  onTap: () {
                    _selectDevice(_devices[index]);
                    setState(() {
                      _searchingMode = false;
                    });
                  },
                  child: Stack(children: [

                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      Text('${_devices[index].deviceName}'),

                      Platform.isAndroid && _defaultPrinterType == PrinterType.usb ? null : Visibility(
                        visible: !Platform.isWindows,
                        child: Text("${_devices[index].address}"),
                      ),

                      index != _devices.length-1 ? Divider(color: Theme.of(context).disabledColor) : SizedBox(),

                    ]),

                    (_selectedPrinter != null && ((_devices[index].typePrinter == PrinterType.usb && Platform.isWindows
                        ? _devices[index].deviceName == _selectedPrinter.deviceName
                        : _devices[index].vendorId != null && _selectedPrinter.vendorId == _devices[index].vendorId) ||
                        (_devices[index].address != null && _selectedPrinter.address == _devices[index].address))) ? Positioned(
                      top: 5, right: 5,
                      child: Icon(Icons.check, color: Colors.green),
                    ) : SizedBox(),

                  ]),
                ),
              );
            },
          ),
          Visibility(
            visible: _defaultPrinterType == PrinterType.network && Platform.isWindows,
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: TextFormField(
                controller: _ipController,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: InputDecoration(
                  label: Text('ip_address'.tr),
                  prefixIcon: Icon(Icons.wifi, size: 24),
                ),
                onChanged: _setIpAddress,
              ),
            ),
          ),
          Visibility(
            visible: _defaultPrinterType == PrinterType.network && Platform.isWindows,
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: TextFormField(
                controller: _portController,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: InputDecoration(
                  label: Text('port'.tr),
                  prefixIcon: Icon(Icons.numbers_outlined, size: 24),
                ),
                onChanged: _setPort,
              ),
            ),
          ),
          Visibility(
            visible: _defaultPrinterType == PrinterType.network && Platform.isWindows,
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: OutlinedButton(
                onPressed: () async {
                  if (_ipController.text.isNotEmpty) _setIpAddress(_ipController.text);
                  setState(() {
                    _searchingMode = false;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 50),
                  child: Text("print_ticket".tr, textAlign: TextAlign.center),
                ),
              ),
            ),
          )
        ],
      ),
    ) : InvoiceDialog(
      order: widget.order, orderDetails: widget.orderDetails,
      onPrint: (i.Image image) => _printReceipt(image),
    );
  }
}

class InvoiceDialog extends StatelessWidget {
  final OrderModel order;
  final List<OrderDetailsModel> orderDetails;
  final Function(i.Image image) onPrint;
  const InvoiceDialog({@required this.order, @required this.orderDetails, @required this.onPrint});

  String _priceDecimal(double price) {
    return price.toStringAsFixed(Get.find<SplashController>().configModel.digitAfterDecimalPoint);
  }

  @override
  Widget build(BuildContext context) {
    double _fontSize = window.physicalSize.width > 1000 ? Dimensions.FONT_SIZE_EXTRA_SMALL : Dimensions.PADDING_SIZE_SMALL;
    ScreenshotController _controller = ScreenshotController();
    Restaurant _restaurant = Get.find<AuthController>().profileModel.restaurants[0];

    double _itemsPrice = 0;
    double _addOns = 0;

    for(OrderDetailsModel orderDetails in orderDetails) {
      for(AddOn addOn in orderDetails.addOns) {
        _addOns = _addOns + (addOn.price * addOn.quantity);
      }
      _itemsPrice = _itemsPrice + (orderDetails.price * orderDetails.quantity);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(Dimensions.PADDING_SIZE_LARGE),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
            boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 700 : 300], spreadRadius: 1, blurRadius: 5)],
          ),
          width: context.width - ((window.physicalSize.width - 700) * 0.4),
          padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
          child: Screenshot(
            controller: _controller,
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              Text(_restaurant.name, style: robotoMedium.copyWith(fontSize: _fontSize)),
              Text(_restaurant.address, style: robotoRegular.copyWith(fontSize: _fontSize)),
              Text(_restaurant.phone, style: robotoRegular.copyWith(fontSize: _fontSize)),
              Text(_restaurant.email, style: robotoRegular.copyWith(fontSize: _fontSize)),
              SizedBox(height: 10),

              Row(children: [
                Text('order_id'.tr + ':', style: robotoRegular.copyWith(fontSize: _fontSize)),
                SizedBox(width: 5),
                Expanded(child: Text(order.id.toString(), style: robotoMedium.copyWith(fontSize: _fontSize))),
                Text(DateConverter.dateTimeStringToMonthAndTime(order.createdAt), style: robotoRegular.copyWith(fontSize: _fontSize)),
              ]),
              order.scheduled == 1 ? Text(
                '${'scheduled_order_time'.tr} ${DateConverter.dateTimeStringToDateTime(order.scheduleAt)}',
                style: robotoRegular.copyWith(fontSize: _fontSize),
              ) : SizedBox(),
              SizedBox(height: 5),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(order.orderType.tr, style: robotoRegular.copyWith(fontSize: _fontSize)),
                Text(order.paymentMethod.tr, style: robotoRegular.copyWith(fontSize: _fontSize)),
              ]),
              Divider(color: Theme.of(context).textTheme.bodyLarge.color, thickness: 1),

              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${order.customer.fName} ${order.customer.lName}', style: robotoRegular.copyWith(fontSize: _fontSize)),
                Text(order.deliveryAddress.address, style: robotoRegular.copyWith(fontSize: _fontSize)),
                Text(order.deliveryAddress.contactPersonNumber, style: robotoRegular.copyWith(fontSize: _fontSize)),
              ]),
              SizedBox(height: 10),

              Row(children: [
                Expanded(flex: 1, child: Text('sl'.tr.toUpperCase(), style: robotoMedium.copyWith(fontSize: _fontSize))),
                Expanded(flex: 6, child: Text('item_info'.tr, style: robotoMedium.copyWith(fontSize: _fontSize))),
                Expanded(flex: 1, child: Text(
                  'qty'.tr, style: robotoMedium.copyWith(fontSize: _fontSize),
                  textAlign: TextAlign.center,
                )),
                Expanded(flex: 2, child: Text(
                  'price'.tr, style: robotoMedium.copyWith(fontSize: _fontSize),
                  textAlign: TextAlign.right,
                )),
              ]),
              Divider(color: Theme.of(context).textTheme.bodyLarge.color, thickness: 1),

              ListView.builder(
                itemCount: orderDetails.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  return Row(children: [
                    Expanded(flex: 1, child: Text(
                      (index+1).toString(),
                      style: robotoRegular.copyWith(fontSize: _fontSize),
                    )),
                    Expanded(flex: 6, child: Text(
                      orderDetails[index].foodDetails.name,
                      style: robotoRegular.copyWith(fontSize: _fontSize),
                    )),
                    Expanded(flex: 1, child: Text(
                      orderDetails[index].quantity.toString(), textAlign: TextAlign.center,
                      style: robotoRegular.copyWith(fontSize: _fontSize),
                    )),
                    Expanded(flex: 2, child: Text(
                      _priceDecimal(orderDetails[index].price), textAlign: TextAlign.right,
                      style: robotoRegular.copyWith(fontSize: _fontSize),
                    )),
                  ]);
                },
              ),
              Divider(color: Theme.of(context).textTheme.bodyLarge.color, thickness: 1),

              PriceWidget(title: 'item_price'.tr, value: _priceDecimal(_itemsPrice), fontSize: _fontSize),
              SizedBox(height: 5),
              _addOns > 0 ? PriceWidget(title: 'add_ons'.tr, value: _priceDecimal(_addOns), fontSize: _fontSize) : SizedBox(),
              SizedBox(height: _addOns > 0 ? 5 : 0),
              PriceWidget(title: 'subtotal'.tr, value: _priceDecimal(_itemsPrice + _addOns), fontSize: _fontSize),
              SizedBox(height: 5),
              PriceWidget(title: 'discount'.tr, value: _priceDecimal(order.restaurantDiscountAmount), fontSize: _fontSize),
              SizedBox(height: 5),
              PriceWidget(title: 'coupon_discount'.tr, value: _priceDecimal(order.couponDiscountAmount), fontSize: _fontSize),
                SizedBox(height: 5),
              PriceWidget(title: 'vat_tax'.tr, value: _priceDecimal(order.totalTaxAmount), fontSize: _fontSize),
              SizedBox(height: 5),
              PriceWidget(title: 'delivery_fee'.tr, value: _priceDecimal(order.deliveryCharge), fontSize: _fontSize),
              Divider(color: Theme.of(context).textTheme.bodyLarge.color, thickness: 1),
              PriceWidget(title: 'total_amount'.tr, value: _priceDecimal(order.orderAmount), fontSize: _fontSize+2),
              Divider(color: Theme.of(context).textTheme.bodyLarge.color, thickness: 1),

              Text('thank_you'.tr, style: robotoRegular.copyWith(fontSize: _fontSize)),
              Divider(color: Theme.of(context).textTheme.bodyLarge.color, thickness: 1),

              Text(
                '${Get.find<SplashController>().configModel.businessName}. ${Get.find<SplashController>().configModel.footerText}',
                style: robotoRegular.copyWith(fontSize: _fontSize),
              ),

            ]),
          ),
        ),
        SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

        CustomButton(buttonText: 'print_invoice'.tr, height: 40, onPressed: () {
          _controller.capture(delay: const Duration(milliseconds: 10)).then((capturedImage) async {
            Get.back();
            onPrint(i.decodeImage(capturedImage));
          }).catchError((onError) {
            print(onError);
          });
        }),

      ]),
    );
  }

}

class PriceWidget extends StatelessWidget {
  final String title;
  final String value;
  final double fontSize;
  const PriceWidget({@required this.title, @required this.value, @required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: robotoRegular.copyWith(fontSize: fontSize)),
      Text(value, style: robotoMedium.copyWith(fontSize: fontSize)),
    ]);
  }
}
