# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'json'
require 'nokogiri'
require 'tempfile'

VAGRANTFILE_API_VERSION = 2
VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_NAME = "homelab-cm-libvirt"
VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_SUBNET = "10.10.100.0/24"
VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_IPV4_ADDR = "10.10.100.1"
VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_SUBNET_MASK = "255.255.255.0"
VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_MAC_ADDR = "52:54:00:4c:7a:ea"
VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_LOWER_BOUND = "10.10.100.2"
VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_UPPER_BOUND = "10.10.100.254"

ANSIBLE_HOST_VARS = JSON.parse(
  File.read("#{ENV['PROJECT_VAGRANT_CONFIGURATION_FILE']}")
)["ansible_host_vars"]

ANSIBLE_GROUPS = JSON.parse(
  File.read("#{ENV['PROJECT_VAGRANT_CONFIGURATION_FILE']}")
)["ansible_groups"]

@libvirt_management_network_xml = Nokogiri::XML.parse(<<-_EOF_)
<network connections='2' ipv6='yes'>
  <name>#{VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_NAME}</name>
  <uuid>206e8c36-866a-4723-a262-011a8152febb</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr2' stp='on' delay='0'/>
  <mac address='#{VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_MAC_ADDR}'/>
  <ip address='#{VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_IPV4_ADDR}' netmask='#{VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_SUBNET_MASK}'>
    <dhcp>
      <range start='#{VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_LOWER_BOUND}' end='#{VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_UPPER_BOUND}'/>
    </dhcp>
  </ip>
</network>
_EOF_

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # general VM configuration
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # general provider configuration
  config.vm.provider "libvirt" do |domains|
    domains.default_prefix = "#{ENV['LIBVIRT_PREFIX']}"
  end

  counter = 0
  ANSIBLE_HOST_VARS.each do |machine_name, machine_attrs|
    # specific VM configuration
    config.vm.define "#{machine_name}" do |machine|
      machine.vm.hostname = "#{machine_name}"
      machine.vm.box = machine_attrs["vagrant_vm_box"]
      # A domain is an instance of an operating system running on a VM. At least
      # according to libvirt. For reference: https://libvirt.org/goals.html
      #
      # VM provider configuration
      machine.vm.provider "libvirt" do |domain|
        domain.cpus = machine_attrs["vagrant_vm_cpus"]
        domain.memory = machine_attrs["vagrant_vm_memory"]
        domain.machine_virtual_size = machine_attrs["vagrant_vm_libvirt_disk_size"] # GBs
        domain.management_network_mac = machine_attrs["vagrant_vm_mac_addr"]
        
        management_network_defined = system("virsh net-info --network #{VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_NAME} > /dev/null 2>&1")
        if !management_network_defined
          host_entry = Nokogiri::XML::Node.new("host", @libvirt_management_network_xml)
          host_entry["mac"] = machine_attrs["vagrant_vm_mac_addr"]
          host_entry["name"] = "#{machine_name}"
          host_entry["ip"] = machine_attrs["vagrant_vm_ipv4_addr"]

          dhcp = @libvirt_management_network_xml.at_css("dhcp")
          dhcp << host_entry
        end
      end

      counter += 1
      # As of Vagrant 2.2.9, the documentation recommends a specific implementation for
      # taking advantage of Ansible's parallelism. Modified to my liking, for reference:
      # https://www.vagrantup.com/docs/provisioning/ansible#ansible-parallel-execution
      if counter == ANSIBLE_HOST_VARS.length
        # provider network configuration
        config.vm.provider "libvirt" do |domains|
          domains.management_network_name = VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_NAME
          domains.management_network_address = VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_SUBNET
          domains.management_network_mac = VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_MAC_ADDR
          management_network_defined = system("virsh net-info --network #{VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_NAME} > /dev/null 2>&1")
          if !management_network_defined
            xml = Tempfile.new("homelab-libvirt.xml")
            xml.write(@libvirt_management_network_xml.to_xml)
            xml.close()
            system("virsh net-define #{xml.path}")
            xml.unlink()
          end
        end
        
        machine.vm.provision "ansible" do |ansible|
          ansible.playbook = "vagrant-customizations.yaml"
          ansible.limit = "all"
          ansible.ask_become_pass = true
          ansible.host_vars = ANSIBLE_HOST_VARS
          ansible.groups = ANSIBLE_GROUPS
          if !ENV["ANSIBLE_VERBOSITY_OPT"].empty?
            ansible.verbose = ENV["ANSIBLE_VERBOSITY_OPT"]
          end
        end

        machine.vm.provision "ansible" do |ansible|
          ansible.playbook = "site.yaml"
          ansible.limit = "all"
          ansible.ask_become_pass = true
          ansible.host_vars = ANSIBLE_HOST_VARS
          ansible.groups = ANSIBLE_GROUPS
          if !ENV["ANSIBLE_VERBOSITY_OPT"].empty?
            ansible.verbose = ENV["ANSIBLE_VERBOSITY_OPT"]
          end
        end
      end
    end
  end
end
