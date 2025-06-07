resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
  depends_on = [
    resource.helm_release.flux_instance
  ]
}


resource "kubectl_manifest" "cert_manager" {
  yaml_body          = file("${path.module}/flux2-manifests/cert-manager-helmrelease.yaml")
  override_namespace = kubernetes_namespace.cert_manager.metadata[0].name
  depends_on         = [kubectl_manifest.jetstack_helmrepository]
  wait_for {
    field {
      key   = "status.conditions.[0].status"
      value = "True"
    }
  }
}
