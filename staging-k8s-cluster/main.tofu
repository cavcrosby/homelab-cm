terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.8.3"
    }
    talos = {
      source  = "siderolabs/talos"
      version = ">= 0.9.0"
    }
  }

  # renovate: datasource=github-releases packageName=opentofu/opentofu versioning=hashicorp
  required_version = "~> 1.11.0"
}

locals {
  network_configs        = yamldecode(file("../.vagrant/network_configs.yml"))
  k8s_controlplane_count = 3
  k8s_worker_count       = 3
  networks = {
    (local.network_configs.homelab_network_name) = {
      is_managed_externally = true
      configs = {
        addresses = [local.network_configs.homelab_network_subnet]
        mode      = "bridge"
      }
      tags = {
        bridge_interface_name = local.network_configs.vmm1_homelab_network_bridge_interface_name
      }
    }
    staging-k8s-cluster = {
      is_managed_externally = false
      configs = {
        addresses = ["192.168.2.0/24"]
        mode      = "none"
      }
      tags = {
        bridge_interface_name = ""
      }
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://libvirt@${local.network_configs.vmm1_homelab_ipv4_addr}/system?no_verify=1"
}

resource "random_string" "domains_suffixes" {
  count   = local.k8s_controlplane_count + local.k8s_worker_count
  length  = 6
  special = false
  upper   = false
}

locals {
  one_gib = 1073741824
  domains = {
    for index in range(local.k8s_controlplane_count + local.k8s_worker_count) :
    index => {
      type   = index < local.k8s_controlplane_count ? "controlplane" : "worker"
      name   = "talos-${substr(random_string.domains_suffixes[index].result, 0, 3)}-${substr(random_string.domains_suffixes[index].result, 3, 3)}"
      vcpu   = 1
      memory = 1024
      size   = local.one_gib * 10
    }
  }
}

resource "libvirt_network" "managed_networks" {
  for_each = {
    for network_name, network_attrs in local.networks : network_name => network_attrs
    if !network_attrs.is_managed_externally
  }
  name      = each.key
  addresses = each.value.configs.addresses
  mode      = each.value.configs.mode
  autostart = true
}

module "libvirt_domains" {
  for_each = local.domains
  source   = "../terraform-libvirt-domain"
  name     = each.value.name
  vcpu     = each.value.vcpu
  memory   = each.value.memory
  size     = each.value.size
  running  = false
  iso_path = "/var/lib/libvirt/images/metal-amd64.iso"
  networks = {
    for network_name, network_attrs in local.networks :
    network_name => {
      mode                  = network_attrs.configs.mode
      bridge_interface_name = network_attrs.tags.bridge_interface_name
    }
  }
}
