class ServiceConfig {
  final String name;
  final int port;
  final Map<String, dynamic> function;

  ServiceConfig({required this.name, required this.port, required this.function});

  factory ServiceConfig.fromJson(Map<String, dynamic> json) {
    return ServiceConfig(
      name: json['name'],
      port: json['port'],
      function: json['function'],
    );
  }

  String getProductListUrl() {
    return '$name:$port${function['getProductList']}';
  }

  String getVerificationCodeUrl() {
    return '$name:$port${function['sendVerificationCode']}';
  }

  String verifyVerificationCodeUrl() {
    return '$name:$port${function['verifyVerificationCode']}';
  }

  String getImagesRootUrl() {
    return '$name:$port';
  }

  String getBaseUrl() {
    return '$name:$port';
  }

  String getProductListPath(){return function['getProductList'];}
  String getVerificationCodePath(){return function['sendVerificationCode'];}
  String verifyVerificationCodePath(){return function['verifyVerificationCode'];}
}
