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
  backend "s3" {
    bucket  = "0d6e4079e367-homelab-cm"
    key     = "prod-k8s-cluster/terraform.tfstate"
    region  = "us-east-1"
    profile = "main-opentofu"
  }

  # renovate: datasource=github-releases packageName=opentofu/opentofu versioning=hashicorp
  required_version = "~> 1.11.0"
}

locals {
  network_configs        = yamldecode(file("../playbooks/vars/network_configs.yml"))
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
        bridge_interface_name = local.network_configs.kronk_homelab_network_bridge_interface_name
        k8s_endpoint_vip      = local.network_configs.homelab_network_k8s_endpoint_vip
        is_k8s_network        = false
        is_mgmt_network       = true
        is_nodeport_network   = true
      }
    }
    prod-k8s-cluster = {
      is_managed_externally = false
      configs = {
        addresses = ["192.168.1.0/24"]
        mode      = "none"
      }
      tags = {
        bridge_interface_name = ""
        is_k8s_network        = true
        is_nodeport_network   = false
      }
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://libvirt@${local.network_configs.kronk_homelab_ipv4_addr}/system"
}

resource "random_string" "domains_suffixes" {
  count   = local.k8s_controlplane_count + local.k8s_worker_count
  length  = 6
  special = false
  upper   = false
}

locals {
  one_gib = 1073741824 # gibibyte
  domains = {
    for index in range(local.k8s_controlplane_count + local.k8s_worker_count) :
    index => {
      type   = index < local.k8s_controlplane_count ? "controlplane" : "worker"
      name   = "talos-${substr(random_string.domains_suffixes[index].result, 0, 3)}-${substr(random_string.domains_suffixes[index].result, 3, 3)}"
      vcpu   = index < local.k8s_controlplane_count ? 4 : 2
      memory = index < local.k8s_controlplane_count ? 4096 : 2048
      size   = local.one_gib * 100
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
  for_each  = local.domains
  source    = "../terraform-libvirt-domain"
  name      = each.value.name
  vcpu      = each.value.vcpu
  memory    = each.value.memory
  autostart = true
  size      = each.value.size
  iso_path  = "/var/lib/libvirt/images/metal-amd64.iso"
  networks = {
    for network_name, network_attrs in local.networks :
    network_name => {
      mode                  = network_attrs.configs.mode
      bridge_interface_name = network_attrs.tags.bridge_interface_name
    }
  }
}

locals {
  nodes = {
    for domain_index, domain_attrs in local.domains :
    domain_attrs.name => {
      type         = domain_attrs.type
      hostname     = domain_attrs.name
      os_disk_path = "/dev/vda"
      network_interfaces = [
        for network_interface in module.libvirt_domains[domain_index].network_interfaces : merge(
          {
            network_name = network_interface.network_name
            mac          = network_interface.mac
            addresses = [
              for address in network_interface.addresses : address
              if !startswith(address, "169.254.") && !startswith(address, "fe80::")
            ]
          },
          local.networks[network_interface.network_name].tags
        )
      ]
    }
  }
}

module "talos_machine_bootstrap" {
  source           = "../terraform-talos-machine-bootstrap"
  k8s_cluster_name = "homelab-cm-prod"
  k8s_base_domain  = local.network_configs.homelab_network_domain
  k8s_network_subnet = [
    for network in local.networks : network.configs.addresses[0]
    if network.tags.is_k8s_network
  ][0]

  k8s_nodeport_addrs = join(",", [
    for network in local.networks : network.configs.addresses[0]
    if network.tags.is_nodeport_network
  ])

  nodes = local.nodes
  talos_config_patches = [
    for node_name, node_attrs in local.nodes :
    {
      (node_name) = yamlencode(
        {
          machine = {
            network = {
              nameservers = [
                local.network_configs.gerald_homelab_ipv4_addr,
                local.network_configs.homelab_network_gateway_ipv4_addr,
              ]
            }
          }
        }
      )
    }
  ]
}

resource "local_file" "k8s_configs" {
  filename = "${path.root}/../playbooks/vars/k8s_configs.yml"
  content = yamlencode({
    k8s_http_ingresses = [
      for node in local.nodes : node.hostname
    ]
  })
}
