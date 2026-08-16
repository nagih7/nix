{ lib, hostVars, ... }:

{
  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNSSEC = "allow-downgrade";
        Domains = [ "~." ];
        FallbackDNS = hostVars.fallback_dns; # Giữ nguyên biến của bạn
        DNSOverTLS = "opportunistic";
        MulticastDNS = "yes";
      };
    };
  };
}
