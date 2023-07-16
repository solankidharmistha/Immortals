class ExpenseBody {
  int totalSize;
  int limit;
  String offset;
  List<Expense> expense;

  ExpenseBody({this.totalSize, this.limit, this.offset, this.expense});

  ExpenseBody.fromJson(Map<String, dynamic> json) {
    totalSize = json['total_size'];
    limit = json['limit'];
    offset = json['offset'];
    if (json['expense'] != null) {
      expense = <Expense>[];
      json['expense'].forEach((v) {
        expense.add(new Expense.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total_size'] = this.totalSize;
    data['limit'] = this.limit;
    data['offset'] = this.offset;
    if (this.expense != null) {
      data['expense'] = this.expense.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Expense {
  int id;
  String type;
  double amount;
  String description;
  String createdAt;
  String updatedAt;
  String createdBy;
  int restaurantId;
  int orderId;

  Expense(
      {this.id,
        this.type,
        this.amount,
        this.description,
        this.createdAt,
        this.updatedAt,
        this.createdBy,
        this.restaurantId,
        this.orderId,
      });

  Expense.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    amount = json['amount'].toDouble();
    description = json['description'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    createdBy = json['created_by'];
    restaurantId = json['restaurant_id'];
    orderId = json['order_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['type'] = this.type;
    data['amount'] = this.amount;
    data['description'] = this.description;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['created_by'] = this.createdBy;
    data['restaurant_id'] = this.restaurantId;
    data['order_id'] = this.orderId;
    return data;
  }
}