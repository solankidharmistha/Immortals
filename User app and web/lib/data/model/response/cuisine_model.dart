class CuisineModel {
  List<Cuisines> cuisines;

  CuisineModel({this.cuisines});

  CuisineModel.fromJson(Map<String, dynamic> json) {
    if (json['Cuisines'] != null) {
      cuisines = <Cuisines>[];
      json['Cuisines'].forEach((v) {
        cuisines.add(new Cuisines.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.cuisines != null) {
      data['Cuisines'] = this.cuisines.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Cuisines {
  int id;
  String name;
  String image;
  int status;
  String slug;
  String createdAt;
  String updatedAt;

  Cuisines(
      {this.id,
        this.name,
        this.image,
        this.status,
        this.slug,
        this.createdAt,
        this.updatedAt});

  Cuisines.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    image = json['image'];
    status = json['status'];
    slug = json['slug'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['image'] = this.image;
    data['status'] = this.status;
    data['slug'] = this.slug;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}