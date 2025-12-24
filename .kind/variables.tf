variable "strimzi_cluster_instance_version" {
  description = "Version of the strimzi-cluster-instance Helm chart"
  type        = string
  default     = "*"
}

variable "gateway_dns_suffix" {
  description = "DNS suffix for gateway routes"
  type        = string
  default     = "strimzi.gateway.api.test"
}
