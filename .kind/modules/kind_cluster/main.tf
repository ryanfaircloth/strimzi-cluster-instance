# kind_cluster module: Provisions the Kind cluster

terraform {
  required_version = ">= 1.0.0"
  required_providers {

    kind = {
      source  = "tehcyx/kind"
      version = "0.9.0"
    }
  }
}


resource "null_resource" "registry" {
  provisioner "local-exec" {
    command = "${path.module}/registry.sh ${var.registry_port}"
  }
}

resource "kind_cluster" "default" {
  name       = var.name
  depends_on = [null_resource.registry]
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    containerd_config_patches = [<<EOT
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:5050"]
    endpoint = ["http://kind-registry:5000"]
EOT
    ]

    node {
      role = "control-plane"
      labels = {
        "topology.kubernetes.io/zone"   = "az-1"
        "topology.kubernetes.io/region" = "kind"
      }
    }
    node {
      role = "worker"
      labels = {
        "topology.kubernetes.io/zone"   = "az-1"
        "topology.kubernetes.io/region" = "kind"
        "test.io/role"                  = "gateway"
      }
      extra_port_mappings {
        container_port = 30994
        host_port      = 9094
      }
    }
    node {
      role = "worker"
      labels = {
        "topology.kubernetes.io/zone"   = "az-1"
        "topology.kubernetes.io/region" = "kind"
        "test.io/role"                  = "sensitive"
      }
    }
    node {
      role = "worker"
      labels = {
        "topology.kubernetes.io/zone"   = "az-1"
        "topology.kubernetes.io/region" = "kind"
        "test.io/role"                  = "worker"
      }
    }
    node {
      role = "worker"
      labels = {
        "topology.kubernetes.io/zone"   = "az-2"
        "topology.kubernetes.io/region" = "kind"
        "test.io/role"                  = "sensitive"
      }
    }
    node {
      role = "worker"
      labels = {
        "topology.kubernetes.io/zone"   = "az-2"
        "topology.kubernetes.io/region" = "kind"
        "test.io/role"                  = "worker"
      }
    }
    node {
      role = "worker"
      labels = {
        "topology.kubernetes.io/zone" = "az-3"
        "topology.kubernetes.io/region" = "kind"
        "test.io/role" = "sensitive"
      }
    }
    node {
      role = "worker"
      labels = {
        "topology.kubernetes.io/zone" = "az-3"
        "topology.kubernetes.io/region" = "kind"
        "test.io/role" = "worker"
      }
    }

  }
}

resource "null_resource" "export_kubeconfig" {
  count = var.export_kubectl_conf ? 1 : 0

  depends_on = [kind_cluster.default]

  provisioner "local-exec" {
    command = "kind export kubeconfig --name ${var.name}"
  }
}
