import 'package:efood_multivendor/data/model/body/deep_link_body.dart';

class LinkConverter{

  static DeepLinkBody convertDeepLink(String link){
    print(link);
    List idx = link.split("/");
    String result = idx[3];
    List fi = result.split("?");
    print('--fi : $fi');

    String type = fi[0];
    List rawId = fi[1].split("=");
    print('--rawId : $rawId');

    String id = rawId[1];
    print('---id: $id');

    String name;
    if(rawId.length > 2) {
      name = rawId[2];
      print('name = $name');
    }

    if(id.contains('&')){
      List cat = id.split('&');
      print('=====$cat');
      id = cat[0];
    }
    print('type= $type');
    print('id = $id');
    print('name = $name');
    DeepLinkType t;
    if(type == 'restaurant'){
      t =  DeepLinkType.restaurant;
    }else if(type == 'cuisine-restaurant'){
      t = DeepLinkType.cuisine;
    }else if(type == 'category-product'){
      t = DeepLinkType.category;
    }
    return DeepLinkBody(deepLinkType: t, id: int.parse(id), name: name);
  }

}

