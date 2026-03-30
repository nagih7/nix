{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    kubectl
    cilium-cli
    kubernetes-helm
    kustomize
    argocd
  ];
}
