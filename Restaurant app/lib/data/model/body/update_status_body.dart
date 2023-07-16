class UpdateStatusBody {
  String token;
  int orderId;
  String status;
  String otp;
  String processingTime;
  String method = 'put';
  String reason;

  UpdateStatusBody({this.token, this.orderId, this.status, this.otp, this.processingTime, this.reason});

  UpdateStatusBody.fromJson(Map<String, dynamic> json) {
    token = json['token'];
    orderId = json['order_id'];
    status = json['status'];
    otp = json['otp'];
    processingTime = json['processing_time'];
    status = json['_method'];
    reason = json['reason'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['token'] = this.token;
    data['order_id'] = this.orderId;
    data['status'] = this.status;
    data['otp'] = this.otp;
    data['processing_time'] = this.processingTime;
    data['_method'] = this.method;
    if(reason != '') {
      data['reason'] = this.reason;
    }
    return data;
  }
}