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
    priority       = string, #Regular or Spot
    eviction_policy = string, #Deallocate or Delete
    mode           = string, #User or System
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

  validation {
    condition = alltrue([ for k, v in var.node_pool  : contains(["Spot", "Regular"], v.priority) ])
    error_message = "Node pool priority allowed value are either \"Spot\" or \"Regular\"."
  }

  validation {
    condition = alltrue([ for k, v in var.node_pool  : contains(["User", "System"], v.mode) ])
    error_message = "Node pool can be either in \"User\" or \"System\" mode."
  }

  validation {
    condition = alltrue([ for k, v in var.node_pool  : contains(["Deallocate", "Delete"], v.eviction_policy) ])
    error_message = "When using Spot instances, please choose between \"Deallocate\" or \"Delete\" for eviction policy."
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

  validation {
    condition     = anytrue([
      can(regex("10(?:\\.(?:[0-1]?[0-9]?[0-9])|(?:2[0-5]?[0-9])){3}\\/", var.service_cidr)),
      can(regex("172\\.(?:1[6-9]|2[0-9]|3[0-1])(?:\\.[0-2]?[0-5]?[0-9]){2}\\/(?:1[2-9]|2[0-9]|3[0-2])", var.service_cidr)),
      can(regex("192\\.168(?:\\.[0-2]?[0-5]?[0-9]){2}\\/(?:1[6-9]|2[0-9]|3[0-2])", var.service_cidr)),
      ])
    error_message = "Must be a valid IPv4 RFC1918 CIDR block."
  }
}

variable "pod_cidr" {
  description = "CIDR block used for pods."
  type = string
  default = "172.17.0.0/16"

  validation {
    condition     = anytrue([
      can(regex("10(?:\\.(?:[0-1]?[0-9]?[0-9])|(?:2[0-5]?[0-9])){3}\\/", var.pod_cidr)),
      can(regex("172\\.(?:1[6-9]|2[0-9]|3[0-1])(?:\\.[0-2]?[0-5]?[0-9]){2}\\/(?:1[2-9]|2[0-9]|3[0-2])", var.pod_cidr)),
      can(regex("192\\.168(?:\\.[0-2]?[0-5]?[0-9]){2}\\/(?:1[6-9]|2[0-9]|3[0-2])", var.pod_cidr)),
      ])
    error_message = "Must be a valid IPv4 RFC1918 CIDR block."
  }
}

variable "acr" {
  description = "Map of Container Registry to allow pull from. If ACR not in same subscription, leave empty and assign role outside module. Expected format is { acr_name = acr_rg }."
  type = map
}

variable "vnet" {
  description = "Name of the VNet where the cluster must be provisioned."
  type = string
}

variable "rg_vnet" {
  description = "Name of the existing VNet resource group where the cluster must be provisioned."
  type = string
}

variable "snet" {
  description = "Name of the existing Subnet where the cluster nodes will be provisioned."
  type = string
}

variable "law" {
  description = "Name of the existing Log Analytics Workspace to link your cluster with."
  type = string
}

variable "rg_law" {
  description = "Name of the existing resource group for the Log Analytics Workspace."
  type = string
}
