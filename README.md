# AKS module
This module creates a kubernetes Cluster, and n node pools based on map(object) provided
- 1 Resource Group named rg-clustername
- 1 AKS resource group with the name rg-clustername_managed
- 1 AKS cluster with Azure CNI Overlay network mode, 
- system assigned identity for the cluster
- "AcrPull" role assignement for the kubelet, on the provided ACR (see variables)
- RBAC is kubernetes with azure AD authentication


## Required resources :
- existing VNet
- existing Subnet
- existing Storage account
- existing log analytics workspace

## Usage Example :
You can insert variables value directly in module call, but a more flexible usage would be to declare root module variables and set their values in tfvars file(s).

```hcl
module "aks" {
  source = "github.com/nfrappart/azTerraAks?ref=v1.0.0"  
  cluster_name = "demo"
  location = "francecentral"
  default_node_pool = {
    enable_auto_scaling = true,
    min_count           = 1,
    max_count           = 5,
    max_pods            = 50,
    vm_size             = "Standard_D2s_v3"
  }
  node_pool = {
    demo = {
      vm_size         = "Standard_D2s_v3",
      priority       = "Spot",
      eviction_policy = "Delete",
      mode           = "User",
      min_nodes       = 1,
      max_nodes       = 5,
      auto_scaling    = true,
      max_pods        = 50,
      taints         = [],
      labels         = {}
    }
  }
  sku = "Free"
  k8s_version = "1.26.3"
  service_cidr = "172.19.0.0/16"
  pod_cidr = "172.17.0.0/16"
  acr = {
    myacr = "rg_acr"
  }
  vnet = "my_vnet"
  rg_vnet = "rg_network"
  snet = "snet_aks"
  law = "myloganalitcs"
  rg_law = "rg_logs"
}
```
