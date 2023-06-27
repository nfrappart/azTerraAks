terraform {
  required_providers {
    azurerm = {}
    azuread = {}
  }
}

locals {
  rg_aks       = "rg-${var.cluster_name}"
  defaultTags = {
    provisioningDate = formatdate("DD-MM-YYYY-hh:mm:ss", timestamp()),
    ProvisioningMode = "Terraform"
  }
}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "azurerm_virtual_network" "vnet" {
  name = var.vnet
  resource_group_name = var.rg_vnet
}
data "azurerm_subnet" "aks" {
  name                 = var.snet
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_virtual_network.vnet.resource_group_name
}

data "azurerm_log_analytics_workspace" "law" {
  name                = var.law
  resource_group_name = var.rg_law
}

data "azurerm_container_registry" "acr" {
  for_each = var.acr
  name                = each.key
  resource_group_name = each.value
}

resource "azuread_group" "aksadmin" {
  display_name     = "k8s_${lower(var.cluster_name)}_admin"
  security_enabled = true
}

resource "azurerm_resource_group" "rg" {
  name     = local.rg_aks
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                       = var.cluster_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  dns_prefix = var.cluster_name
  kubernetes_version         = var.k8s_version

  default_node_pool {
    name                = "system"
    zones               = ["1", "2", "3"]
    node_count          = var.default_node_pool.min_count
    enable_auto_scaling = var.default_node_pool.enable_auto_scaling
    min_count           = var.default_node_pool.min_count
    max_count           = var.default_node_pool.max_count
    max_pods            = var.default_node_pool.max_pods
    vm_size             = var.default_node_pool.vm_size
    vnet_subnet_id      = data.azurerm_subnet.aks.id
  }

  node_resource_group = "rg-${title(var.cluster_name)}_managed"

  network_profile {
    network_plugin     = "azure"
    network_plugin_mode = "overlay"
    pod_cidr = var.pod_cidr
    service_cidr       = var.service_cidr
    dns_service_ip     = cidrhost(var.service_cidr, 10)
  }

  sku_tier = var.sku

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled = true

  role_based_access_control_enabled = true

  azure_policy_enabled = true

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = false
    admin_group_object_ids = [
      azuread_group.aksadmin.object_id
    ]
  }

  oms_agent {
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  }

  microsoft_defender {
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  }

  tags = local.defaultTags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      tags
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "pool" {
  for_each              = var.node_pool
  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vnet_subnet_id        = data.azurerm_subnet.aks.id
  vm_size               = each.value.vm_size
  mode                  = each.value.mode
  zones                 = ["1", "2", "3"]
  min_count             = each.value.min_nodes
  max_count             = each.value.max_nodes
  enable_auto_scaling   = each.value.auto_scaling
  max_pods              = each.value.max_pods
  node_taints           = each.value.taints
  node_labels           = each.value.labels
  priority              = each.value.priority
  eviction_policy       = each.value.priority == "Spot" ? each.value.eviction_policy : null

  tags = local.defaultTags

  lifecycle {
    ignore_changes = [
      node_count,
      node_labels,
      node_taints,
      tags
    ]
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  for_each = var.acr
  scope                            = data.azurerm_container_registry.acr[each.key].id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}