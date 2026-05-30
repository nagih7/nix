{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    kubectl
    k9s
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
