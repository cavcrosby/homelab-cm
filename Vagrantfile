# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'json'
require 'nokogiri'
require 'tempfile'
require 'fileutils'

VAGRANTFILE_API_VERSION = 2
SHELL_VARIABLE_REGEX = /\$([a-zA-Z_]\w*)$|\$\{{1}(\w+)\}{1}/
VAGRANT_NETWORK_CONFIGS_PATH = "./.vagrant/network_configs.yml"
VAGRANT_LIBVIRT_HOMELAB_DOMAIN = "homelab.staging.cavcrosby.net"
VAGRANT_CONFIG_JSON = JSON.parse(
  File.read("#{ENV['PROJECT_VAGRANT_CONFIGURATION_FILE']}")
)

ansible_host_vars = VAGRANT_CONFIG_JSON["ansible_host_vars"]
ansible_groups = VAGRANT_CONFIG_JSON["ansible_groups"]
ansible_groups["managed:children"] = []
ansible_groups.keys().each do |name|
  if !name.match?(/:children|:vars/)
    ansible_groups["managed:children"] << name
  end
end

if VAGRANT_CONFIG_JSON.key?("vms_include")
  VMS_INCLUDE = VAGRANT_CONFIG_JSON["vms_include"]
end

vagrant_homelab_network_configs = {
  "homelab_network_domain" => VAGRANT_LIBVIRT_HOMELAB_DOMAIN,
  "homelab_poseidon_k8s_network_domain" => "poseidon.#{VAGRANT_LIBVIRT_HOMELAB_DOMAIN}",
  "homelab_poseidon_vrrp_server_vip" => "192.168.2.2",
  "homelab_network_subnet" => "192.168.1.0/24",
  "homelab_network_gateway_ipv4_addr" => "192.168.1.1",
  "homelab_network_subnet_mask" => "255.255.255.0",
  "homelab_network_lower_bound" => "192.168.1.50",
  "homelab_network_upper_bound" => "192.168.1.254",
  "vpn_network_subnet" => "192.168.4.0/24",
  "vpn_network_clients" => [
    {
      "pubkey" => "M22Z/H+1Fg4EOfn8xrjM7g2K6qchJa+d+SyszP7yGzI=",
      "address" => "192.168.4.45/24"
    },
    {
      "pubkey" => "jKADq3XliV2+u9pKqBaOYVc+FK3U0EKkJ2xwrkJ6dC0=",
      "address" => "192.168.4.46/24"
    },
    {
      "pubkey" => "mR1PkypwAOR8QPs49O2D2yecpJTYxn9WmyKO7//R+mk=",
      "address" => "192.168.4.47/24"
    }
  ]
}

# exported constants
VAGRANT_LIBVIRT_HOMELAB_NETWORK_IPV4_ADDR = vagrant_homelab_network_configs["homelab_network_gateway_ipv4_addr"]
VAGRANT_LIBVIRT_POSEIDON_K8S_NETWORK_IPV4_ADDR = "192.168.2.1"
VAGRANT_LIBVIRT_VPN_NETWORK_IPV4_ADDR = "192.168.4.1"
VAGRANT_VPN_CLIENT_1_PUBKEY = vagrant_homelab_network_configs["vpn_network_clients"][0]["pubkey"]
VAGRANT_VPN_CLIENT_2_PUBKEY = vagrant_homelab_network_configs["vpn_network_clients"][1]["pubkey"]
VAGRANT_VPN_CLIENT_3_PUBKEY = vagrant_homelab_network_configs["vpn_network_clients"][2]["pubkey"]

def eval_config_ref(machine_attrs, config)
  # A config=>config_ref is a JSON key=>value pair whose value is a key in
  # machine_attrs.
  has_children = true

  if config.kind_of?(Array)
    nil
  else
    # lets at first assume that all JSON key values do not have children
    has_children = false

    config.each do |config_name, config_ref|
      if !(config_ref.kind_of?(Array) || config_ref.kind_of?(Hash))
        # eval each JSON's key value
        if machine_attrs.key?(config_ref)
          config[config_name] = machine_attrs[config_ref]
        elsif SHELL_VARIABLE_REGEX.match?(config_ref)
          match = SHELL_VARIABLE_REGEX.match(config_ref)
          config[config_name] = eval(match[1].nil? ? match[2] : match[1])
        end
      elsif config_ref.kind_of?(Hash) && config_ref.key?("join")
        # If an a JSON's key value is another JSON with a sole 'join' element, then the
        # "joins" value will be combined into one string. For example:
        # {
        #     "filename": {
        #         "join": [
        #             "eth0",
        #             ".link"
        #         ]
        #     }
        # }
        #
        # Will become:
        # {
        #     "filename": "eth0.link"
        # }
        config_ref["join"].each_index do |str_index|
          if machine_attrs.key?(config_ref["join"][str_index])
            config_ref["join"][str_index] = machine_attrs[config_ref["join"][str_index]]
          end
        end

        config[config_name] = config_ref["join"].join()
      else
        has_children = true
      end
    end
  end

  return has_children
end

def traverse_configs(func, machine_attrs, config_node)
  if config_node.class == String || !(func.call(machine_attrs, config_node))
    return
  end

  if config_node.kind_of?(Array)
    config_node.each do |config_node_child|
      traverse_configs(func, machine_attrs, config_node_child)
    end
  else
    config_node.values().each do |config_node_child|
      traverse_configs(func, machine_attrs, config_node_child)
    end
  end
end

ansible_host_vars.each do |machine_name, machine_attrs|
  # hostnames may use dashes but Ansible variables cannot
  machine_name_dash_replaced = machine_name.gsub("-", "_")
  vagrant_homelab_network_configs["#{machine_name_dash_replaced}_homelab_mac_addr"] = machine_attrs["vagrant_vm_homelab_mac_addr"]
  vagrant_homelab_network_configs["#{machine_name_dash_replaced}_homelab_ipv4_addr"] = machine_attrs["vagrant_vm_homelab_ipv4_addr"]

  if machine_attrs.key?("vagrant_vm_poseidon_k8s_mac_addr")
    vagrant_homelab_network_configs["#{machine_name_dash_replaced}_poseidon_k8s_mac_addr"] = machine_attrs["vagrant_vm_poseidon_k8s_mac_addr"]
    vagrant_homelab_network_configs["#{machine_name_dash_replaced}_poseidon_k8s_ipv4_addr"] = machine_attrs["vagrant_vm_poseidon_k8s_ipv4_addr"]
  end

  if machine_attrs.key?("vagrant_vm_vpn_mac_addr")
    vagrant_homelab_network_configs["#{machine_name_dash_replaced}_vpn_mac_addr"] = machine_attrs["vagrant_vm_vpn_mac_addr"]
    vagrant_homelab_network_configs["#{machine_name_dash_replaced}_vpn_mac_addr"] = machine_attrs["vagrant_vm_poseidon_k8s_ipv4_addr"]
  end

  if (defined? VMS_INCLUDE) && !VMS_INCLUDE.include?(machine_name)
    ansible_host_vars.delete(machine_name)
    next
  end

  # Takes each key value pair in vagrant_config_refs and inserts it into
  # machine_attrs but with the value eval'd based on machine_attrs[value].
  if machine_attrs.key?("vagrant_config_refs")
    vagrant_config_refs = machine_attrs["vagrant_config_refs"]
    # passing a function as a argument was inspired by:
    # https://stackoverflow.com/questions/522720/passing-a-method-as-a-parameter-in-ruby#answer-4094968
    traverse_configs(method(:eval_config_ref), machine_attrs, vagrant_config_refs)

    vagrant_config_refs.keys().each do |config_name|
      config_ref = vagrant_config_refs[config_name]
      if config_ref.kind_of?(Array) || config_ref.kind_of?(Hash)
        machine_attrs[config_name] = "'#{config_ref.to_json}'"
      else
        machine_attrs[config_name] = config_ref
      end
    end

    # Since all the key values pairs are resolved and put at the machine_attrs level,
    # for now the config_refs json will be discarded.
    machine_attrs.delete("vagrant_config_refs")
  end

  # Takes each key value pair in vagrant_external_config_refs and inserts it into
  # machine_attrs but with the value eval'd based on
  # ansible_host_vars[machine_name][value].
  if machine_attrs.key?("vagrant_external_config_refs")
    machine_attrs["vagrant_external_config_refs"].each do |machine_name, vagrant_external_config_refs|
      if (!defined? VMS_INCLUDE) || VMS_INCLUDE.include?(machine_name)
        traverse_configs(method(:eval_config_ref), ansible_host_vars[machine_name], vagrant_external_config_refs)
        vagrant_external_config_refs.keys().each do |config_name|
          machine_attrs[config_name] = vagrant_external_config_refs[config_name]
        end
      end
    end

    machine_attrs.delete("vagrant_external_config_refs")
  end

  # Evals each key value pair's value in domain_config based on
  # ansible_host_vars[domain_config[name]].
  if machine_attrs.key?("libvirt_poseidon_k8s_controller_domain_configs")
    domain_configs = machine_attrs["libvirt_poseidon_k8s_controller_domain_configs"]
    domain_configs.each do |domain_config|
      traverse_configs(method(:eval_config_ref), ansible_host_vars[domain_config["name"]], domain_config)
    end
    machine_attrs["libvirt_poseidon_k8s_controller_domain_configs"] = "'#{domain_configs.to_json}'"
  end

  if machine_attrs.key?("libvirt_poseidon_k8s_worker_domain_configs")
    domain_configs = machine_attrs["libvirt_poseidon_k8s_worker_domain_configs"]
    domain_configs.each do |domain_config|
      traverse_configs(method(:eval_config_ref), ansible_host_vars[domain_config["name"]], domain_config)
    end
    machine_attrs["libvirt_poseidon_k8s_worker_domain_configs"] = "'#{domain_configs.to_json}'"
  end
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_NAME = "mgmt-homelab-cm"
  TRUTHY_VALUES = [
    "1",
    "true"
  ]

  # general VM configuration
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # general VM provider configuration
  config.vm.provider "libvirt" do |domains|
    domains.default_prefix = "#{ENV['LIBVIRT_PREFIX']}"
    domains.management_network_name = VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_NAME
    domains.management_network_address = "192.168.3.0/24"
  end

  @libvirt_management_network_xml = Nokogiri::XML.parse(<<-_EOF_)
<network ipv6='yes'>
  <name>#{VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_NAME}</name>
  <uuid>206e8c36-866a-4723-a262-011a8152febb</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <mac address='52:54:00:4c:7a:ea'/>
  <ip address='192.168.3.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.3.3' end='192.168.3.254'/>
    </dhcp>
  </ip>
</network>
_EOF_

  counter = 0
  management_network_defined = system("virsh net-info --network #{VAGRANT_LIBVIRT_MANAGEMENT_NETWORK_NAME} > /dev/null 2>&1")
  ansible_host_vars.each do |machine_name, machine_attrs|
    # specific VM configuration
    config.vm.define "#{machine_name}" do |machine|
      machine.vm.hostname = "#{machine_name}"
      machine.vm.box = machine_attrs["vagrant_vm_box"]
      machine.vm.network "private_network",
        mac: machine_attrs["vagrant_vm_homelab_mac_addr"],
        libvirt__network_name: "homelab-cm",
        libvirt__host_ip: vagrant_homelab_network_configs["homelab_network_gateway_ipv4_addr"],
        libvirt__dhcp_enabled: false

      if machine_attrs.key?("vagrant_vm_poseidon_k8s_mac_addr")
        machine.vm.network "private_network",
          mac: machine_attrs["vagrant_vm_poseidon_k8s_mac_addr"],
          ip: machine_attrs["vagrant_vm_poseidon_k8s_ipv4_addr"],
          libvirt__network_name: "poseidon-k8s-homelab-cm",
          libvirt__host_ip: VAGRANT_LIBVIRT_POSEIDON_K8S_NETWORK_IPV4_ADDR,
          libvirt__dhcp_enabled: false
      end

      if machine_attrs.key?("vagrant_vm_vpn_mac_addr")
        machine.vm.network "private_network",
          mac: machine_attrs["vagrant_vm_vpn_mac_addr"],
          ip: machine_attrs["vagrant_vm_vpn_ipv4_addr"],
          libvirt__network_name: "vpn-homelab-cm",
          libvirt__host_ip: VAGRANT_LIBVIRT_VPN_NETWORK_IPV4_ADDR,
          libvirt__dhcp_enabled: false,
          libvirt__forward_mode: "veryisolated"
      end

      # A domain is an instance of an operating system running on a VM. At least
      # according to libvirt. For reference: https://libvirt.org/goals.html
      #
      # VM provider configuration
      disks_config = machine_attrs["lvm_disks_config"]
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

        if !disks_config.nil?
          # aggregate pv disks arrays to create a unique list of pv disks
          Set.new(disks_config["vgs"].map{|vg| vg["pvs"]["disks"]}.flatten).each do |pv_disk|
            domain.storage :file, device: File.basename(pv_disk)
          end
        end
      end

      if !disks_config.nil?
        machine_attrs["lvm_disks_config"] = "'#{disks_config.to_json}'"
      end

      counter += 1
      # As of Vagrant 2.2.9, the documentation recommends a specific implementation for
      # taking advantage of Ansible's parallelism. Modified to my liking, for reference:
      # https://www.vagrantup.com/docs/provisioning/ansible#ansible-parallel-execution
      if counter == ansible_host_vars.length
        if !management_network_defined
          # associates the vagrant management network xml with libvirt
          xml = Tempfile.new("mgmt-homelab-libvirt.xml")
          xml.write(@libvirt_management_network_xml.to_xml)
          xml.close()
          system("virsh net-define #{xml.path}")
          xml.unlink()
        end

        ansible_extra_vars = {}
        if !ENV["ANSIBLE_EXTRA_VARS"].empty?
          ENV["ANSIBLE_EXTRA_VARS"].split(/ |=/).each_slice(2) do |var_name, var_value|
            ansible_extra_vars[var_name] = var_value
          end
        end

        # write out the vagrant network configuration to be consumed by the playbooks
        File.write(VAGRANT_NETWORK_CONFIGS_PATH, vagrant_homelab_network_configs.to_yaml)

        ansible_groups["on_prem:vars"] = {
          "preferred_nameserver" => ansible_host_vars["staging-node1"]["vagrant_vm_homelab_ipv4_addr"]
        }

        ansible_host_vars["staging-node1"]["se_domains"] = "'#{ansible_host_vars["staging-node1"]["se_domains"].to_json}'"
        ansible_host_vars["vmm1"]["nfs_exports_config"] = "'#{ansible_host_vars["vmm1"]["nfs_exports_config"].to_json}'"
        ansible_host_vars["poseidon-k8s-controller1"]["zim_jobs_manifest_configs"] = "'#{ansible_host_vars["poseidon-k8s-controller1"]["zim_jobs_manifest_configs"].to_json}'"
        ansible_groups["poseidon:vars"]["nfs_exports_config"] = "'#{ansible_groups["poseidon:vars"]["nfs_exports_config"].to_json}'"

        if TRUTHY_VALUES.include? ENV["USE_MAINTENANCE_PLAYBOOK"]
          machine.vm.provision "ansible" do |ansible|
            ansible.playbook = "./playbooks/maintenance.yml"
            ansible.compatibility_mode = "2.0"
            ansible.limit = ENV.fetch("ANSIBLE_LIMIT", "all")
            ansible.ask_become_pass = true
            ansible.tags = ENV["ANSIBLE_TAGS"]
            ansible.host_vars = ansible_host_vars
            ansible.groups = ansible_groups
          end
        elsif TRUTHY_VALUES.include? ENV["USE_LOCALHOST_PLAYBOOK"]
          FileUtils::mkdir_p("./.vagrant/provisioners/ansible/inventory")
          File.write(
            "./.vagrant/provisioners/ansible/inventory/localhost",
            {
              "all" => {
                "hosts" => {
                  "localhost" => {
                    "ansible_host" => "127.0.0.1",
                    "ansible_connection" => "local",
                    "homelab_preferred_nameserver" => ansible_host_vars["staging-node1"]["homelab_dnsmasq_dns_listen_ipv4_addr"],
                    "vpn_preferred_nameserver" => ansible_host_vars["staging-node1"]["vpn_dnsmasq_dns_listen_ipv4_addr"],
                    "wireguard_endpoint" => "vpn.#{VAGRANT_LIBVIRT_HOMELAB_DOMAIN}:#{ansible_host_vars['staging-node1']['wireguard_server_port']}"
                  }
                }
              }
            }.to_yaml
          )

          machine.vm.provision "ansible" do |ansible|
            ansible.playbook = "./playbooks/localhost.yml"
            ansible.compatibility_mode = "2.0"
            ansible.limit = ENV.fetch("ANSIBLE_LIMIT", "all")
            ansible.ask_become_pass = true
            ansible.tags = ENV["ANSIBLE_TAGS"]
            ansible.host_vars = ansible_host_vars
            ansible.groups = ansible_groups
            ansible.extra_vars = {
              wireguard_privkey_path: ENV["WIREGUARD_PRIVKEY_PATH"],
              wireguard_network_interface_name: ENV["WIREGUARD_NETWORK_INTERFACE_NAME"],
              associated_network_interface_type: ENV["ASSOCIATED_NETWORK_INTERFACE_TYPE"],
              associated_network_interface_name: ENV["ASSOCIATED_NETWORK_INTERFACE_NAME"],
              wireguard_server_pubkey: ENV["WIREGUARD_SERVER_PUBKEY"],
              network_configs_path: File.join("..", VAGRANT_NETWORK_CONFIGS_PATH[1..VAGRANT_NETWORK_CONFIGS_PATH.length]),
              enable_dhcp: false
            }.merge(ansible_extra_vars)
          end
        else
          machine.vm.provision "ansible" do |ansible|
            ansible.playbook = "./playbooks/vagrant_customizations.yml"
            ansible.compatibility_mode = "2.0"
            ansible.limit = ENV.fetch("ANSIBLE_LIMIT", "all")
            ansible.ask_become_pass = true
            ansible.tags = ENV["ANSIBLE_TAGS"]
            ansible.host_vars = ansible_host_vars
            ansible.groups = ansible_groups
          end

          machine.vm.provision "ansible" do |ansible|
            ansible.playbook = "./playbooks/site.yml"
            ansible.compatibility_mode = "2.0"
            ansible.limit = ENV.fetch("ANSIBLE_LIMIT", "all")
            ansible.ask_become_pass = true
            ansible.tags = ENV["ANSIBLE_TAGS"]
            ansible.host_vars = ansible_host_vars
            ansible.groups = ansible_groups
            ansible.extra_vars = {
              network_configs_path: File.join("..", VAGRANT_NETWORK_CONFIGS_PATH[1..VAGRANT_NETWORK_CONFIGS_PATH.length])
            }.merge(ansible_extra_vars)
          end
        end
      end
    end
  end
end
