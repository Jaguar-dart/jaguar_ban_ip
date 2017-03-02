// Copyright (c) 2017, SERAGUD. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

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
