// Copyright (c) 2017, teja. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:jaguar/jaguar.dart';
import 'package:jaguar_ipnet/jaguar_ipnet.dart';

/// Options for IPFilter. Allowed takes precedence over Blocked.
/// IPs can be IPv4 or IPv6 and can optionally contain subnet
/// masks (/24).
class IPFilterOptions {
  /// explicitly allowed IPs and IP nets
  final List<String> allowedIPs;

  /// explicitly blocked IPs and IP nets
  final List<String> blockedIPs;

  /* TODO
  /// explicitly allowed country ISO codes
  final List<String> allowedCountries;

  /// explicitly blocked country ISO codes
  final List<String> blockedCountries;
  */

  /// block by default (defaults to allow)
  final bool blockByDefault;

  /// Message to be sent as body of response if the IP is blocked
  final String message;

  const IPFilterOptions(this.blockedIPs,
      {this.allowedIPs,
        /* TODO this.allowedCountries,
      this.blockedCountries, */
      this.blockByDefault,
      this.message = "Forbidden!"});

  CompiledIPFilter compile() {
    final ips = <String, bool>{};
    final nets = <int, Map<String, bool>>{};

    for (String blocked in blockedIPs) {
      try {
        final Ip4Net net = Ip4Net.parseCIDR(blocked);
        Map<String, bool> map = nets[net.mask.cidrLen];
        if (map is! Map) {
          map = <String, bool>{};
          nets[net.mask.cidrLen] = map;
        }
        map[net.network.toString()] = false;
        continue;
      } on Exception {}

      ips[blocked] = false;
    }

    for (String allowed in allowedIPs) {
      try {
        final Ip4Net net = Ip4Net.parseCIDR(allowed);
        Map<String, bool> map = nets[net.mask.cidrLen];
        if (map is! Map) {
          map = <String, bool>{};
          nets[net.mask.cidrLen] = map;
        }
        map[net.network.toString()] = true;
        continue;
      } on Exception {}

      ips[allowed] = true;
    }

    return new CompiledIPFilter(ips,
        nets: nets, message: message, blockByDefault: blockByDefault);
  }
}

class CompiledIPFilter {
  /// explicitly allowed IPs and IP nets
  final Map<String, bool> ips;

  final Map<int, Map<String, bool>> nets;

  final String message;

  final bool blockByDefault;

  CompiledIPFilter(this.ips,
      {this.nets: const {},
      this.message: "Forbidden!",
      this.blockByDefault: true});

  /// Returns if a given IP can pass through the filter
  bool isIPAllowed(String ip) {
    if (ip is! String) return false;

    if (ips.containsKey(ip)) return ips[ip];

    //TODO handle ip6

    final ip4 = Ip4.parse(ip);

    for (int cidrLen in nets.keys) {
      final masked = ip4.masked(new Ip4.cidr(cidrLen)).toString();

      final Map<String, bool> n = nets[cidrLen];
      if (n.containsKey(masked)) return n[masked];
    }

    //TODO check country

    return blockByDefault;
  }

  bool isIPBlocked(String ip) => !isIPAllowed(ip);
}

/// Wraps [IPFilter] that filters requests based on IP addresses
class WrapIPFilter extends RouteWrapper<IPFilter> {
  final IPFilterOptions options;

  const WrapIPFilter(this.options);

  IPFilter createInterceptor() => new IPFilter(options.compile());
}

/// An interceptor to filter requests based on IP addresses
///
/// The interceptor is configured using [options]
///
/// Throws [IPBannedError] if the IP is determined to be blocked
class IPFilter extends Interceptor {
  final CompiledIPFilter options;

  IPFilter(this.options);

  void pre(Request req) {
    //TODO also check X-Fowarded-For and friends
    final String ip = req.connectionInfo.remoteAddress.address;
    if (!options.isIPAllowed(ip)) {
      throw new IPBannedError(options.message);
    }
  }
}

/// Error thrown when the IP of the request is blocked
class IPBannedError extends JaguarError {
  IPBannedError(String message)
      : super(HttpStatus.FORBIDDEN, "Forbidden", message);

  String toString() => message;
}
