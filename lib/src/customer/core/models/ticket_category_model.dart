// models/ticket_category_model.dart

class TicketCategoryResponse {
  final String status;
  final String message;
  final List<CategoryData> data;

  TicketCategoryResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory TicketCategoryResponse.fromJson(Map<String, dynamic> json) {
    List<CategoryData> dataList = [];
    if (json['data'] is List) {
      dataList =
          (json['data'] as List)
              .map(
                (item) => CategoryData.fromJson(item as Map<String, dynamic>),
              )
              .toList();
    }

    return TicketCategoryResponse(
      status: json['status'] as String,
      message: json['message'] as String,
      data: dataList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class CategoryData {
  final int categoryId;
  final String categoryName;
  final List<SubCategory> subcategories;

  CategoryData({
    required this.categoryId,
    required this.categoryName,
    required this.subcategories,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    List<SubCategory> subList = [];
    if (json['subcategories'] is List) {
      subList =
          (json['subcategories'] as List)
              .map((item) => SubCategory.fromJson(item as Map<String, dynamic>))
              .toList();
    }

    return CategoryData(
      categoryId: json['category_id'] as int,
      categoryName: json['category_name'] as String,
      subcategories: subList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'subcategories': subcategories.map((e) => e.toJson()).toList(),
    };
  }
}

class SubCategory {
  final int subcategoryId;
  final String subcategoryName;

  SubCategory({required this.subcategoryId, required this.subcategoryName});

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      subcategoryId: json['subcategory_id'] as int,
      subcategoryName: json['subcategory_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subcategory_id': subcategoryId,
      'subcategory_name': subcategoryName,
    };
  }
}
