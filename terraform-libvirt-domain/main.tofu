terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.8.3"
    }
  }
}

resource "libvirt_volume" "domain" {
  name = var.name
  size = var.size
}

resource "libvirt_domain" "main" {
  name       = var.name
  vcpu       = var.vcpu
  memory     = var.memory
  qemu_agent = true
  running    = var.running
  autostart  = var.autostart

  cpu {
    mode = "host-passthrough"
  }

  dynamic "network_interface" {
    for_each = [
      for network_name, network_attrs in var.networks : network_name
      if network_attrs.mode != "bridge"
    ]

    content {
      network_name = network_interface.value
    }
  }

  dynamic "network_interface" {
    for_each = [
      for network in var.networks : network.bridge_interface_name
      if network.mode == "bridge"
    ]

    content {
      bridge = network_interface.value
    }
  }

  boot_device {
    dev = ["hd", "cdrom"]
  }

  disk {
    volume_id = libvirt_volume.domain.id
  }

  disk {
    file = var.iso_path
  }
}
