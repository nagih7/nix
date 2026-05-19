{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    kubectl
    kubeconform
    cilium-cli
    kubernetes-helm
    kustomize
    argocd
    vault
  ];

  home.shellAliases = {
    tf = "terraform";
  };
}
