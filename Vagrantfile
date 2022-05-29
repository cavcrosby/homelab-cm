# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'json'
require 'nokogiri'
require 'tempfile'

VAGRANTFILE_API_VERSION = 2
VAGRANT_NETWORK_CONFIGS_PATH = "./.vagrant/network_configs.yml"

VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_NAME = "mgmt-homelab-cm-libvirt"
VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_SUBNET = "192.168.111.0/24"
VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_IPV4_ADDR = "192.168.111.1"
VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_SUBNET_MASK = "255.255.255.0"
VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_MAC_ADDR = "52:54:00:4c:7a:ea"
VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_LOWER_BOUND = "192.168.111.2"
VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_UPPER_BOUND = "192.168.111.254"

VAGRANT_LIBVIRT_HOMELAB_NETWORK_NAME = "homelab-cm-libvirt"
VAGRANT_LIBVIRT_HOMELAB_NETWORK_SUBNET = "10.10.100.0/24"
VAGRANT_LIBVIRT_HOMELAB_NETWORK_IPV4_ADDR = "10.10.100.1"
VAGRANT_LIBVIRT_HOMELAB_NETWORK_SUBNET_MASK = "255.255.255.0"
VAGRANT_LIBVIRT_HOMELAB_NETWORK_LOWER_BOUND = "10.10.100.50"
VAGRANT_LIBVIRT_HOMELAB_NETWORK_UPPER_BOUND = "10.10.100.254"
VAGRANT_LIBVIRT_HOMELAB_DOMAIN = "staging-homelab.cavcrosby.tech"

ANSIBLE_HOST_VARS = JSON.parse(
  File.read("#{ENV['PROJECT_VAGRANT_CONFIGURATION_FILE']}")
)["ansible_host_vars"]

# Replaces each key value pair in vagrant_config_refs with values based on
# machine_attrs[key] and inserts the new key value pair into machine_attrs.
ANSIBLE_HOST_VARS.each do |machine_name, machine_attrs|
  if machine_attrs.key?("vagrant_config_refs")
    vagrant_config_refs = machine_attrs["vagrant_config_refs"]
    vagrant_config_refs.each do |config_name, config_ref|
      machine_attrs[config_name] = machine_attrs[config_ref]
    end
    # Since all the key values pairs are resolved and put at the machine_attrs level,
    # for now I will just discard the config_refs json.
    machine_attrs.delete("vagrant_config_refs")
  end
end

ANSIBLE_GROUPS = JSON.parse(
  File.read("#{ENV['PROJECT_VAGRANT_CONFIGURATION_FILE']}")
)["ansible_groups"]

@libvirt_management_network_xml = Nokogiri::XML.parse(<<-_EOF_)
<network ipv6='yes'>
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

# inspired by:
# https://stackoverflow.com/questions/53093316/ruby-to-yaml-colon-in-keys#answer-53093339
VAGRANT_HOMELAB_NETWORK_CONFIGS = {
  homelab_network_domain: VAGRANT_LIBVIRT_HOMELAB_DOMAIN,
  homelab_network_subnet: VAGRANT_LIBVIRT_HOMELAB_NETWORK_SUBNET,
  homelab_network_gateway_ipv4_addr: VAGRANT_LIBVIRT_HOMELAB_NETWORK_IPV4_ADDR,
  homelab_network_subnet_mask: VAGRANT_LIBVIRT_HOMELAB_NETWORK_SUBNET_MASK,
  homelab_network_lower_bound: VAGRANT_LIBVIRT_HOMELAB_NETWORK_LOWER_BOUND,
  homelab_network_upper_bound: VAGRANT_LIBVIRT_HOMELAB_NETWORK_UPPER_BOUND,
  dns_local_domain: "{{ homelab_network_domain }}",
  dns_subnet: "{{ homelab_network_subnet }}"
}

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # general VM configuration
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # general VM provider configuration
  config.vm.provider "libvirt" do |domains|
    domains.default_prefix = "#{ENV['LIBVIRT_PREFIX']}"
    domains.management_network_name = VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_NAME
    domains.management_network_address = VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_SUBNET
  end

  counter = 0
  management_network_defined = system("virsh net-info --network #{VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_NAME} > /dev/null 2>&1")
  ANSIBLE_HOST_VARS.each do |machine_name, machine_attrs|
    # hostnames may use dashes but Ansible variables cannot
    machine_name_dash_replaced = machine_name.gsub("-", "_")
    VAGRANT_HOMELAB_NETWORK_CONFIGS["#{machine_name_dash_replaced}_mac_addr"] = machine_attrs["vagrant_vm_homelab_mac_addr"]
    VAGRANT_HOMELAB_NETWORK_CONFIGS["#{machine_name_dash_replaced}_ipv4_addr"] = machine_attrs["vagrant_vm_homelab_ipv4_addr"]

    # specific VM configuration
    config.vm.define "#{machine_name}" do |machine|
      machine.vm.hostname = "#{machine_name}"
      machine.vm.box = machine_attrs["vagrant_vm_box"]
      machine.vm.network "private_network",
        mac: machine_attrs["vagrant_vm_homelab_mac_addr"],
        libvirt__network_name: VAGRANT_LIBVIRT_HOMELAB_NETWORK_NAME,
        libvirt__host_ip: VAGRANT_LIBVIRT_HOMELAB_NETWORK_IPV4_ADDR,
        libvirt__dhcp_enabled: false

      # A domain is an instance of an operating system running on a VM. At least
      # according to libvirt. For reference: https://libvirt.org/goals.html
      #
      # VM provider configuration
      machine.vm.provider "libvirt" do |domain|
        domain.cpus = machine_attrs["vagrant_vm_cpus"]
        domain.memory = machine_attrs["vagrant_vm_memory"]
        domain.machine_virtual_size = machine_attrs["vagrant_vm_libvirt_disk_size"] # GBs
        domain.management_network_mac = machine_attrs["vagrant_vm_mgmt_mac_addr"]

        if !management_network_defined and @libvirt_management_network_xml.xpath("//host[@name='#{machine_name}']").empty?
          host_entry = Nokogiri::XML::Node.new("host", @libvirt_management_network_xml)
          host_entry["mac"] = machine_attrs["vagrant_vm_mgmt_mac_addr"]
          host_entry["name"] = "#{machine_name}"
          host_entry["ip"] = machine_attrs["vagrant_vm_mgmt_ipv4_addr"]

          dhcp = @libvirt_management_network_xml.at_css("dhcp")
          dhcp << host_entry
        end
      end

      counter += 1
      # As of Vagrant 2.2.9, the documentation recommends a specific implementation for
      # taking advantage of Ansible's parallelism. Modified to my liking, for reference:
      # https://www.vagrantup.com/docs/provisioning/ansible#ansible-parallel-execution
      if counter == ANSIBLE_HOST_VARS.length
        if !management_network_defined
          # associates the vagrant management network xml with libvirt
          xml = Tempfile.new("mgmt-homelab-libvirt.xml")
          xml.write(@libvirt_management_network_xml.to_xml)
          xml.close()
          system("virsh net-define #{xml.path}")
          xml.unlink()
        end

        # write out the vagrant network configuration to be consumed by the playbooks
        File.write(VAGRANT_NETWORK_CONFIGS_PATH, VAGRANT_HOMELAB_NETWORK_CONFIGS.transform_keys(&:to_s).to_yaml)
        
        machine.vm.provision "ansible" do |ansible|
          ansible.playbook = "./playbooks/ansible_controllers.yml"
          ansible.compatibility_mode = "2.0"
          ansible.limit = "all"
          ansible.ask_become_pass = true
          ansible.tags = ENV["ANSIBLE_TAGS"]
          ansible.host_vars = ANSIBLE_HOST_VARS
          ansible.groups = ANSIBLE_GROUPS
          ansible.extra_vars = {
            network_configs_path: File.join("..", VAGRANT_NETWORK_CONFIGS_PATH[1..VAGRANT_NETWORK_CONFIGS_PATH.length]),
            dhcp_config_file_template_name: "vagrant-dnsmasq-dhcp.conf.j2",
            dns_config_file_template: "vagrant-dnsmasq-dns.conf.j2"
          }
          if !ENV["ANSIBLE_VERBOSITY_OPT"].empty?
            ansible.verbose = ENV["ANSIBLE_VERBOSITY_OPT"]
          end
        end
      
        machine.vm.provision "ansible" do |ansible|
          ansible.playbook = "./playbooks/vagrant_customizations.yml"
          ansible.compatibility_mode = "2.0"
          ansible.limit = "all"
          ansible.ask_become_pass = true
          ansible.tags = ENV["ANSIBLE_TAGS"]
          ansible.host_vars = ANSIBLE_HOST_VARS
          ansible.groups = ANSIBLE_GROUPS
          if !ENV["ANSIBLE_VERBOSITY_OPT"].empty?
            ansible.verbose = ENV["ANSIBLE_VERBOSITY_OPT"]
          end
        end

        machine.vm.provision "ansible" do |ansible|
          ansible.playbook = "./playbooks/site.yml"
          ansible.compatibility_mode = "2.0"
          ansible.limit = "all"
          ansible.ask_become_pass = true
          ansible.tags = ENV["ANSIBLE_TAGS"]
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
