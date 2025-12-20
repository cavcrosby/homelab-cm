output "network_interfaces" {
  value = [
    for network_interface in libvirt_domain.main.network_interface :
    network_interface.bridge == "" || network_interface.bridge == null ? network_interface : merge(
      network_interface,
      {
        network_name = [
          for network_name, network_attrs in var.networks : network_name
          if network_attrs.bridge_interface_name == network_interface.bridge
        ][0]
      }
    )
  ]
}
