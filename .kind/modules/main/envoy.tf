resource "kubernetes_namespace" "envoy_gateway_system" {
  metadata {
    name = "envoy-gateway-system"
  }

  depends_on = [
    resource.helm_release.flux_instance
  ]
}

resource "kubectl_manifest" "envoyproxy_charts_oci_helmrepository" {
  yaml_body          = file("${path.module}/flux2-manifests/envoyproxy-charts-oci-helmrepository.yaml")
  override_namespace = kubernetes_namespace.flux_system.metadata[0].name
  depends_on         = [helm_release.flux_instance]
}

resource "kubectl_manifest" "envoyproxy_helmrelease" {
  yaml_body          = file("${path.module}/flux2-manifests/envoyproxy-helmrelease.yaml")
  override_namespace = kubernetes_namespace.envoy_gateway_system.metadata[0].name
  depends_on         = [kubectl_manifest.envoyproxy_charts_oci_helmrepository]
  wait_for {
    field {
      key   = "status.conditions.[0].status"
      value = "True"
    }
  }

}

