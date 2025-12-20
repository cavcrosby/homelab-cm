variable "name" {
  description = "The domain's name."
  type        = string
}

variable "vcpu" {
  description = "The amount of virtual CPUs for the domain."
  type        = number
}

variable "memory" {
  description = "The amount of memory for the domain."
  type        = number
}

variable "running" {
  description = "Whether to start the domains."
  type        = bool
  default     = true
}

variable "autostart" {
  description = "Whether to start the domain upon boot."
  type        = bool
  default     = false
}

variable "size" {
  description = "The volume size for the domain."
  type        = number
}

variable "iso_path" {
  description = "The path to the domain's ISO file."
  type        = string
}

variable "networks" {
  description = "The networks the domain will be attached to."
  type = map(
    object({
      mode                  = string
      bridge_interface_name = optional(string, "")
    })
  )

  validation {
    condition = alltrue([
      for network in var.networks : contains(
        ["none", "nat", "route", "open", "bridge"],
        network.mode,
      )
    ])
    error_message = format(
      "Each network's `mode` attribute should be set to none, nat, route, open, or bridge. var.networks => %v",
      var.networks,
    )
  }

  validation {
    condition = alltrue([
      for network in var.networks : network.bridge_interface_name != ""
      if network.mode == "bridge"
    ])
    error_message = format(
      "Each network's `bridge_interface_name` attribute should be non-empty when the network's `mode` attribute is set to bridge. var.networks => %v",
      var.networks,
    )
  }
}
