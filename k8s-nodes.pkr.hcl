packer {
  required_plugins {
    qemu = {
      # renovate: datasource=github-releases packageName=hashicorp/packer-plugin-qemu versioning=hashicorp
      version = "= 1.0.9"
      source  = "github.com/hashicorp/qemu"
    }
    ansible = {
      # renovate: datasource=github-releases packageName=hashicorp/packer-plugin-ansible versioning=hashicorp
      version = "= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }

  # renovate: datasource=github-releases packageName=hashicorp/packer versioning=hashicorp
  required_version = "~> 1.10.0"
}

variable "preferred_nameserver" {
  type        = string
  description = "A IP address that follows the nameserver option from 'resolv.conf(5)'."
}

variable "ansible_user_password" {
  type        = string
  description = "A plaintext password for the ansible_user."
}

variable "timezone_offset" {
  type        = string
  description = "A string representation of a time difference."
}

locals {
  iso_url              = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.2.0-amd64-netinst.iso"
  iso_checksum         = "sha256:23ab444503069d9ef681e3028016250289a33cc7bab079259b73100daee0af66"
  ssh_username         = "ansible"
  ssh_private_key_file = "~/.ssh/id_ed25519"
  preseed_file         = "${path.root}/playbooks/files/packer/preseed.cfg"
  boot_command = [
    "<esc><wait>",
    "/install.amd/vmlinuz ",
    "initrd=/install.amd/initrd.gz ",
    "auto-install/enable=true ",
    "debconf/priority=critical ",
    "netcfg/hostname=debian ",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/./preseed.cfg<enter><wait>",
  ]
}

source "qemu" "poseidon_k8s_controller" {
  iso_url              = local.iso_url
  iso_checksum         = local.iso_checksum
  output_directory     = "./playbooks/files/packer/qemu-poseidon_k8s_controller"
  format               = "qcow2"
  ssh_username         = local.ssh_username
  ssh_private_key_file = local.ssh_private_key_file
  shutdown_command     = "echo '${var.ansible_user_password}' | sudo --stdin shutdown --poweroff now"
  memory               = 2048
  disk_size            = "20G"
  ssh_timeout          = "20m"
  ssh_pty              = true

  http_content = {
    "/preseed.cfg"                     = file(local.preseed_file)
    "/playbooks/files/authorized_keys" = file("${path.root}/playbooks/files/authorized_keys"),
    "/scripts/late-commands"           = file("${path.root}/scripts/late-commands")
  }
  qemuargs = [
    [
      "-smp", "cpus=1"
    ],
  ]
  boot_command = local.boot_command
}

source "qemu" "poseidon_k8s_worker" {
  iso_url              = local.iso_url
  iso_checksum         = local.iso_checksum
  output_directory     = "./playbooks/files/packer/qemu-poseidon_k8s_worker"
  format               = "qcow2"
  ssh_username         = local.ssh_username
  ssh_private_key_file = local.ssh_private_key_file
  shutdown_command     = "echo '${var.ansible_user_password}' | sudo --stdin shutdown --poweroff now"
  memory               = 2048
  disk_size            = "30G"
  ssh_timeout          = "20m"
  ssh_pty              = true

  http_content = {
    "/preseed.cfg"                     = file(local.preseed_file)
    "/playbooks/files/authorized_keys" = file("${path.root}/playbooks/files/authorized_keys")
    "/scripts/late-commands"           = file("${path.root}/scripts/late-commands")
  }
  qemuargs = [
    [
      "-smp", "cpus=1"
    ],
  ]
  boot_command = local.boot_command
}

build {
  sources = [
    "source.qemu.poseidon_k8s_controller",
    "source.qemu.poseidon_k8s_worker"
  ]

  provisioner "ansible" {
    playbook_file = "./playbooks/packer_customizations.yml"
    user          = "ansible"
    use_proxy     = false
    extra_arguments = [
      "--extra-vars",
      "ansible_become_pass='${var.ansible_user_password}'",
      "--extra-vars",
      "preferred_nameserver='${var.preferred_nameserver}'"
    ]

    override = {
      poseidon_k8s_controller = {
        groups = [
          "k8s_controllers"
        ],
        ansible_env_vars = [
          "ANSIBLE_LOG_PATH=./logs/ansible.log.${formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), var.timezone_offset))}-${substr(uuidv4(), 0, 5)}"
        ]
      }
      poseidon_k8s_worker = {
        groups = [
          "k8s_workers"
        ],
        ansible_env_vars = [
          "ANSIBLE_LOG_PATH=./logs/ansible.log.${formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), var.timezone_offset))}-${substr(uuidv4(), 0, 5)}"
        ]
      }
    }
  }

  post-processor "shell-local" {
    inline = [
      "mv --verbose \"./playbooks/files/packer/${source.type}-${source.name}/packer-${source.name}\" \"./playbooks/files/packer/${source.type}-${source.name}/${source.name}.qcow2\""
    ]
  }
}
