{ ... }:

{
  # Includes redistributable firmware plus the non-redistributable blobs
  # (allowUnfree is on globally).
  hardware.enableAllFirmware = true;
}
