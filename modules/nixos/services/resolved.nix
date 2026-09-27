{ config, ... }:

{
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      Domains = [ "~." ];
      FallbackDNS = config.host.fallbackDns;
      DNSOverTLS = "opportunistic";
      MulticastDNS = "yes";
    };
  };
}
