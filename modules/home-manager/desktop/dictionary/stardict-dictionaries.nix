# StarDict dictionaries fetched by URL and hash, because nixpkgs carries none.
#
# There is nothing Vietnamese in nixpkgs at all: `dictdDBs` covers only
# de/fr/ja/nl/ru/epo, and there is no freedict or stardict dictionary package
# (checked against this flake's own nixpkgs, not the channel). So an Anh-Việt
# dictionary has to come from outside — and doing it with fetchurl + a hash
# keeps it as declarative and reproducible as the rest of this config, instead
# of a tarball hand-unpacked into ~/.local/share that no rebuild can recreate.
#
# The data is the Free Vietnamese Dictionary Project (FVDP) by Hồ Ngọc Đức,
# packaged for StarDict and mirrored on huzheng.org, the long-standing StarDict
# dictionary mirror. Both are small: 5.4 MB and 1.0 MB.
#
# To add another of the dictionaries on that mirror, get its hash with
#   nix-prefetch-url http://download.huzheng.org/misc/stardict-dictd_<slug>-2.4.2.tar.bz2
# and add an entry below. viet-viet, phap-viet, duc-viet and nauy-viet exist
# there too.
{ lib, pkgs }:

let
  mkDictionary =
    {
      slug,
      hash,
      description,
    }:
    pkgs.stdenvNoCC.mkDerivation {
      pname = "stardict-${slug}";
      version = "2.4.2";

      src = pkgs.fetchurl {
        url = "http://download.huzheng.org/misc/stardict-dictd_${slug}-2.4.2.tar.bz2";
        sha256 = hash;
      };

      # A StarDict dictionary is three static files — an .ifo header, an .idx
      # of headwords and a dictzipped .dict.dz. Nothing to configure or build.
      dontConfigure = true;
      dontBuild = true;

      # share/stardict/dic is not arbitrary: it is what sdcv treats as a data
      # directory, so this path can be handed to --data-dir unchanged.
      installPhase = ''
        runHook preInstall
        install -Dm444 -t "$out/share/stardict/dic" ./*.ifo ./*.idx ./*.dict.dz
        runHook postInstall
      '';

      meta = {
        inherit description;
        homepage = "http://www.informatik.uni-leipzig.de/~duc/Dict/";
        # FVDP publishes these as free to use and redistribute without naming
        # one of the standard licences, and the StarDict repackaging adds no
        # statement of its own, so this stays deliberately unspecific rather
        # than asserting a GPL that cannot be pointed at.
        license = lib.licenses.free;
        platforms = lib.platforms.all;
      };
    };
in
{
  anh-viet = mkDictionary {
    slug = "anh-viet";
    hash = "0gypaqzwmbxyaadq8xx27hbxma1m6p60hx6nfclr0b72szwm6wa2";
    description = "English-Vietnamese dictionary (FVDP), StarDict format";
  };

  viet-anh = mkDictionary {
    slug = "viet-anh";
    hash = "05f7aqm4inj1lc9qagf7jflh88q78wkw3ir7xg513mh56wakn685";
    description = "Vietnamese-English dictionary (FVDP), StarDict format";
  };
}
