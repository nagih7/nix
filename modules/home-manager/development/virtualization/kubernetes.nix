{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    kubectl
    kubeconform
    cilium-cli
    kubernetes-helm
    kustomize
    argocd
  ];

  home.shellAliases = {
    tf = "terraform";
  };
}
