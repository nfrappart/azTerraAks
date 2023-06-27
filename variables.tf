variable "cluster_name" {
  description = "Name your AKS cluster"
  type        = string
}

variable "location" {
  description = "Location for Aks resources."
  type        = string
}

variable "default_node_pool" {
  description = "Default node pool is system type, for cluster system pods. Cautious, vm size can't be changed."
  type = object({
    enable_auto_scaling = bool,
    min_count           = number,
    max_count           = number,
    max_pods            = number,
    vm_size             = string
  })
  default = {
    enable_auto_scaling = true,
    min_count           = 1,
    max_count           = 5,
    max_pods            = 50,
    vm_size             = "Standard_D2s_v3"
  }
}

variable "node_pool" {
  description = "Collection of node pool objects to provision for workloads to run on."
  type = map(object({
    vm_size         = string,
    priority       = string,
    eviction_policy = string,
    mode           = string,
    min_nodes       = number,
    max_nodes       = number,
    auto_scaling    = bool,
    max_pods        = number,
    taints         = list(string),
    labels         = map(string)
  }))

  validation {
    condition     = can({ for k, v in var.node_pool : regex("[0-9a-z]", k) => v }) || var.node_pool == {}
    error_message = "Node pool name must be lowercase alphanum."
  }
}

variable "sku" {
  description = "Sku defines if this cluster has SLA or not."
  type        = string
  default     = "Free"
}

variable "k8s_version" {
  description = "Defines kubnernetes version used at provisioning."
  type        = string
  #default     = "1.25.5"
}

variable "service_cidr" {
  description = "CIDR block used for kubernetes services."
  type        = string
  default     = "172.19.0.0/16"
}

variable "pod_cidr" {
  description = "CIDR block used for pods."
  type = string
  default = "172.17.0.0/16"
}

variable "acr" {
  description = "Map of Container Registry to allow pull from. Expected format is { acr_name = acr_rg }"
  type = map
}