locals {
  talos_version = "v1.11.5"
  endpoints_addrs = [
    for normalized_node in local.normalized_nodes : normalized_node.mgmt_ipv4_addr
    if normalized_node.type == "controlplane"
  ]

  normalized_nodes = {
    for node_name, node_attrs in var.nodes : node_name => {
      type               = node_attrs.type
      hostname           = node_attrs.hostname
      os_disk_path       = node_attrs.os_disk_path
      network_interfaces = node_attrs.network_interfaces
      mgmt_ipv4_addr = [
        for network_interface in node_attrs.network_interfaces : network_interface.addresses[0]
        if network_interface.is_mgmt_network
      ][0]
    }
  }
}

terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = ">= 0.9.0"
    }
  }
}

resource "talos_machine_secrets" "main" {
  talos_version = local.talos_version
}

data "talos_client_configuration" "main" {
  cluster_name         = var.k8s_cluster_name
  client_configuration = talos_machine_secrets.main.client_configuration
  endpoints            = local.endpoints_addrs
  nodes                = [for normalized_node in local.normalized_nodes : normalized_node.mgmt_ipv4_addr]
}

resource "local_file" "talosconfig" {
  filename = "${path.root}/talosconfig"
  content  = data.talos_client_configuration.main.talos_config
}

locals {
  talos_installer_image     = "factory.talos.dev/metal-installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:${local.talos_version}"
  k8s_kube_apiserver_domain = "kube-api-${substr(sha256(var.k8s_cluster_name), 0, 5)}.${var.k8s_base_domain}"
  k8s_cluster_endpoint      = "https://${local.k8s_kube_apiserver_domain}:6443"
  k8s_version               = "v1.34.2"
}

data "talos_machine_configuration" "controlplanes" {
  for_each = {
    for node_name, node_attrs in local.normalized_nodes : node_name => node_attrs
    if node_attrs.type == "controlplane"
  }
  machine_type     = each.value.type
  cluster_name     = var.k8s_cluster_name
  cluster_endpoint = local.k8s_cluster_endpoint
  machine_secrets  = talos_machine_secrets.main.machine_secrets
  config_patches = concat(
    [
      yamlencode(
        {
          machine = {
            install = {
              disk  = each.value.os_disk_path
              image = local.talos_installer_image
            }
            network = {
              hostname = each.value.hostname
              interfaces = [
                for network_interface in each.value.network_interfaces :
                {
                  dhcp = true
                  deviceSelector = {
                    hardwareAddr = lower(network_interface.mac)
                  }
                  vip = {
                    ip = network_interface.k8s_endpoint_vip
                  }
                }
                if network_interface.k8s_endpoint_vip != ""
              ]
            }
            kubelet = {
              image = "ghcr.io/siderolabs/kubelet:${local.k8s_version}"
              nodeIP = {
                validSubnets = [var.k8s_network_subnet]
              }
              extraArgs = {
                rotate-server-certificates = true
              }
              extraConfig = {
                serverTLSBootstrap = true
              }
            }
          }
          cluster = {
            id          = talos_machine_secrets.main.machine_secrets.cluster.id
            secret      = talos_machine_secrets.main.machine_secrets.cluster.secret
            clusterName = var.k8s_cluster_name
            network = {
              dnsDomain      = "k8s.${var.k8s_base_domain}"
              podSubnets     = ["172.16.0.0/16"]
              serviceSubnets = ["172.17.0.0/23"]
            }
            apiServer = {
              image    = "registry.k8s.io/kube-apiserver:${local.k8s_version}"
              certSANs = [local.k8s_kube_apiserver_domain]
            }
            controlPlane = {
              endpoint = local.k8s_cluster_endpoint
            }
            controllerManager = {
              image = "registry.k8s.io/kube-controller-manager:${local.k8s_version}"
            }
            proxy = {
              image = "registry.k8s.io/kube-proxy:${local.k8s_version}"
              extraArgs = {
                nodeport-addresses = var.k8s_nodeport_addrs
              }
            }
            scheduler = {
              image = "registry.k8s.io/kube-scheduler:${local.k8s_version}"
            }
            etcd = {
              advertisedSubnets = [var.k8s_network_subnet]
            }
            extraManifests = [
              "https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/main/deploy/standalone-install.yaml",
              "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml",
            ]
          }
        }
      )
    ],
    compact([
      for talos_config_patch in var.talos_config_patches : lookup(
        talos_config_patch,
        each.key,
        null,
      )
    ]),
  )
}

data "talos_machine_configuration" "workers" {
  for_each = {
    for node_name, node_attrs in local.normalized_nodes : node_name => node_attrs
    if node_attrs.type == "worker"
  }
  machine_type     = each.value.type
  cluster_name     = var.k8s_cluster_name
  cluster_endpoint = local.k8s_cluster_endpoint
  machine_secrets  = talos_machine_secrets.main.machine_secrets
  config_patches = concat(
    [
      yamlencode(
        {
          machine = {
            install = {
              disk  = each.value.os_disk_path
              image = local.talos_installer_image
            }
            network = {
              hostname = each.value.hostname
            }
            kubelet = {
              image = "ghcr.io/siderolabs/kubelet:${local.k8s_version}"
              nodeIP = {
                validSubnets = [var.k8s_network_subnet]
              }
              extraArgs = {
                rotate-server-certificates = true
              }
              extraConfig = {
                serverTLSBootstrap = true
              }
            }
          }
          cluster = {
            id          = talos_machine_secrets.main.machine_secrets.cluster.id
            secret      = talos_machine_secrets.main.machine_secrets.cluster.secret
            clusterName = var.k8s_cluster_name
            network = {
              dnsDomain      = "k8s.${var.k8s_base_domain}"
              podSubnets     = ["172.16.0.0/16"]
              serviceSubnets = ["172.17.0.0/23"]
            }
            controlPlane = {
              endpoint = local.k8s_cluster_endpoint
            }
          }
        }
      )
    ],
    compact([
      for talos_config_patch in var.talos_config_patches : lookup(
        talos_config_patch,
        each.key,
        null,
      )
    ]),
  )
}

resource "talos_machine_configuration_apply" "nodes" {
  for_each             = local.normalized_nodes
  client_configuration = talos_machine_secrets.main.client_configuration
  machine_configuration_input = (
    each.value.type == "controlplane"
    ? data.talos_machine_configuration.controlplanes[each.key].machine_configuration
    : data.talos_machine_configuration.workers[each.key].machine_configuration
  )
  node = each.value.mgmt_ipv4_addr
}

resource "talos_machine_bootstrap" "main" {
  depends_on = [
    talos_machine_configuration_apply.nodes
  ]
  client_configuration = talos_machine_secrets.main.client_configuration
  node                 = local.endpoints_addrs[0]
}

resource "talos_cluster_kubeconfig" "main" {
  depends_on = [
    talos_machine_bootstrap.main
  ]
  client_configuration = talos_machine_secrets.main.client_configuration
  node                 = local.endpoints_addrs[0]
}

resource "local_file" "kubeconfig" {
  filename = "${path.root}/kubeconfig"
  content  = talos_cluster_kubeconfig.main.kubeconfig_raw
}
