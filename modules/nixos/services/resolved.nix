{ lib, hostVars, ... }:

{
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    domains = [ "~." ];
    fallbackDns = hostVars.fallback_dns;
    extraConfig = ''
      DNSOverTLS=opportunistic
      MulticastDNS=yes
    '';
  };
}
