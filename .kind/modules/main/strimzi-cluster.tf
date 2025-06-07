

# Namespace for strimzi-cluster-instance HelmRelease
resource "kubernetes_namespace" "kafka" {
  metadata {
    name = "kafka"
  }
  depends_on = [
    resource.helm_release.flux_instance
  ]
}

# Local HelmRepository for localregistry (OCI)
resource "kubectl_manifest" "localregistry_helmrepository" {
  yaml_body          = file("${path.module}/flux2-manifests/localregistry-helmrepository.yaml")
  override_namespace = var.flux_namespace
  depends_on         = [helm_release.flux_instance]
}


# HelmRelease for strimzi-cluster-instance from localregistry
resource "kubectl_manifest" "strimzi_cluster_instance_helmrelease" {
  yaml_body = templatefile("${path.module}/flux2-manifests/strimzi-cluster-instance-helmrelease.yaml", {
    strimzi_cluster_instance_version = var.strimzi_cluster_instance_version
  })
  override_namespace = kubernetes_namespace.kafka.metadata[0].name
  depends_on         = [kubectl_manifest.localregistry_helmrepository]
  wait_for {
    field {
      key   = "status.conditions.[0].status"
      value = "True"
    }
  }
}

