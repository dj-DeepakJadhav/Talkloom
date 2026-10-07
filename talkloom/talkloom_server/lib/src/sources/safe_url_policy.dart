import 'dart:io';

typedef HostResolver = Future<List<InternetAddress>> Function(String host);

/// Validation shared by the endpoint and the network fetcher.
///
/// Every resolved address must be globally routable. Rejecting the whole DNS
/// answer when it contains even one unsafe address prevents clients from
/// selecting the private answer from a mixed public/private response.
class SafeUrlPolicy {
  const SafeUrlPolicy();

  static const maxUrlLength = 2048;

  static Uri parsePublicWebUrl(String input) {
    if (input.length > maxUrlLength) {
      throw ArgumentError('The link is too long.');
    }
    final uri = Uri.tryParse(input.trim());
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.hasPort && uri.port != 443)) {
      throw ArgumentError(
        'Use a public HTTPS link without credentials or a custom port.',
      );
    }
    if (InternetAddress.tryParse(uri.host) != null) {
      throw ArgumentError('Links to IP addresses are not supported.');
    }
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'\.$'), '');
    if (host == 'localhost' ||
        host.endsWith('.localhost') ||
        host.endsWith('.local')) {
      throw ArgumentError('Private network links are not supported.');
    }
    return uri;
  }

  static Future<List<InternetAddress>> resolvePublicAddresses(
    Uri uri, {
    required HostResolver resolver,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    parsePublicWebUrl(uri.toString());
    final addresses = await resolver(uri.host).timeout(timeout);
    if (addresses.isEmpty || addresses.any(_isBlockedAddress)) {
      throw ArgumentError(
        'This link resolves to a private or reserved network.',
      );
    }
    return addresses;
  }

  static bool _isBlockedAddress(InternetAddress address) {
    if (address.isLoopback || address.isLinkLocal || address.isMulticast) {
      return true;
    }

    final bytes = address.rawAddress;
    if (address.type == InternetAddressType.IPv6) {
      if (bytes.length != 16) return true;
      final allZero = bytes.take(16).every((byte) => byte == 0);
      if (allZero ||
          (bytes.take(15).every((byte) => byte == 0) && bytes.last == 1)) {
        return true;
      }
      // IPv4-mapped IPv6 still has the IPv4 address's routing semantics.
      if (bytes.take(10).every((byte) => byte == 0) &&
          bytes[10] == 0xff &&
          bytes[11] == 0xff) {
        return _isBlockedIpv4(bytes.sublist(12));
      }
      final first = bytes[0];
      final second = bytes[1];
      return (first & 0xfe) == 0xfc || // unique-local
          (first == 0xfe && (second & 0xc0) == 0x80) || // link-local
          first == 0xff || // multicast
          (first == 0x20 &&
              second == 0x01 &&
              bytes[2] == 0x0d &&
              bytes[3] == 0xb8); // docs
    }

    return _isBlockedIpv4(bytes);
  }

  static bool _isBlockedIpv4(List<int> bytes) {
    if (bytes.length != 4) return true;
    final a = bytes[0], b = bytes[1];
    return a == 0 || // unspecified/current network
        a == 10 || // private
        a == 127 || // loopback
        a >= 224 || // multicast/reserved
        (a == 100 && b >= 64 && b <= 127) || // shared address space
        (a == 169 && b == 254) || // link-local
        (a == 172 && b >= 16 && b <= 31) || // private
        (a == 192 && b == 168) || // private
        (a == 192 && b == 0 && bytes[2] == 0) || // protocol assignments
        (a == 192 && b == 0 && bytes[2] == 2) || // docs
        (a == 198 && (b == 18 || b == 19)) || // benchmark
        (a == 198 && b == 51 && bytes[2] == 100) || // docs
        (a == 203 && b == 0 && bytes[2] == 113); // docs
  }
}
