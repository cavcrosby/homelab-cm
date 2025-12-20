variable "k8s_cluster_name" {
  description = "The name of the Kubernetes cluster."
  type        = string
}

variable "k8s_base_domain" {
  description = "The domain where the Kubernetes network and kube-apiserver subdomains are appended."
  type        = string
}

variable "k8s_network_subnet" {
  description = "The subnet used for kubelet and etcd communication."
  type        = string
}

variable "k8s_nodeport_addrs" {
  description = "The comma-delimited list of subnets used for accessing NodePort services."
  type        = string
}

variable "nodes" {
  description = "The nodes' configurations."
  type = map(
    object({
      type         = string
      hostname     = string
      os_disk_path = string
      network_interfaces = list(
        object({
          mac              = string
          addresses        = list(string)
          k8s_endpoint_vip = optional(string, "")
          is_mgmt_network  = optional(bool, false) # network primarily used to reach nodes
        })
      )
    })
  )

  validation {
    condition = length(compact([
      for node in var.nodes : node
      if !contains(["controlplane", "worker"], node.type)
    ])) == 0
    error_message = format(
      "Each node's `type` attribute should be set to either controlplane or worker. var.nodes => %v",
      var.nodes,
    )
  }

  validation {
    condition = alltrue([
      for node in var.nodes : length([
        for network_interface in node.network_interfaces : network_interface
        if network_interface.is_mgmt_network
      ]) > 0
    ])
    error_message = format(
      "Each node's `network_interfaces` attribute must have a network interface assigned to the management network. var.nodes => %v",
      var.nodes,
    )
  }

  validation {
    condition = alltrue([
      for node in var.nodes : length([
        for network_interface in node.network_interfaces : network_interface
        if network_interface.is_mgmt_network && length(network_interface.addresses) > 0
      ]) > 0
    ])
    error_message = format(
      "Each node's `network_interfaces` attribute must have a management network interface with an IP address. var.nodes => %v",
      var.nodes,
    )
  }
}

variable "talos_config_patches" {
  description = "Additional machine configuration patches to append."
  type        = list(map(string))
  default     = []
}
