# jaguar_ban_ip

Interceptors and functions to filter requests based on IP addresses

## Usage

A simple usage example:

````dart
import 'package:jaguar/jaguar.dart';
import 'package:jaguar_reflect/jaguar_reflect.dart';
import 'package:jaguar_ban_ip/jaguar_ban_ip.dart';

@Api(path: '/api')
class ExampleApi {
  @Get(path: '/info')
  @WrapIPFilter(const IPFilterOptions(const ['127.0.0.0/8'])) //Blocks loopback IPs
  String info() => "A very secret message!";
}

main() async {
  Jaguar server = new Jaguar();
  server.addApi(reflectJaguar(new ExampleApi()));
  await server.serve();
}
````

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/Jaguar-dart/jaguar_ban_ip/issues
