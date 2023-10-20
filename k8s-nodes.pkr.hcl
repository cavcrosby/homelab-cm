packer {
  required_plugins {
    qemu = {
      version = "= 1.0.9"
      source  = "github.com/hashicorp/qemu"
    }
  }

  required_version = "~> 1.8.0"
}

variable "ssh_password" {
  type        = string
  description = "A plaintext password to use to authenticate with SSH."
}

variable "encrypted_ssh_password" {
  type        = string
  description = "The plaintext password hashed by a method supported by crypt(5)."
}

locals {
  iso_url              = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.2.0-amd64-netinst.iso"
  iso_checksum         = "sha256:23ab444503069d9ef681e3028016250289a33cc7bab079259b73100daee0af66"
  ssh_username         = "ansible"
  ssh_private_key_file = "~/.ssh/id_rsa"
  preseed_tpl_file     = "${path.root}/preseed.pkrtpl.hcl"
  boot_command = [
    "<esc><wait>",
    "/install.amd/vmlinuz ",
    "initrd=/install.amd/initrd.gz ",
    "auto-install/enable=true ",
    "debconf/priority=critical ",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/./preseed.cfg<enter><wait>",
  ]
}

source "qemu" "poseidon_k8s_controller" {
  iso_url              = local.iso_url
  iso_checksum         = local.iso_checksum
  output_directory     = "./playbooks/packer/qemu-poseidon_k8s_controller"
  format               = "qcow2"
  ssh_username         = local.ssh_username
  ssh_private_key_file = local.ssh_private_key_file
  shutdown_command     = "echo '${var.ssh_password}' | sudo --stdin shutdown --poweroff now"
  memory               = 2048
  disk_size            = "20G"
  ssh_timeout          = "20m"
  ssh_pty              = true

  http_content = {
    "/preseed.cfg" = templatefile(local.preseed_tpl_file, {
      password = var.encrypted_ssh_password
    })
    "/authorized_keys" = join(
      "",
      [
        file("${path.root}/playbooks/ssh_keys/id_rsa_ron.pub"),
        file("${path.root}/playbooks/ssh_keys/id_rsa_roxanne.pub")
      ]
    ),
    "/late_commands" = file("${path.root}/scripts/late_commands")
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
  output_directory     = "./playbooks/packer/qemu-poseidon_k8s_worker"
  format               = "qcow2"
  ssh_username         = local.ssh_username
  ssh_private_key_file = local.ssh_private_key_file
  shutdown_command     = "echo '${var.ssh_password}' | sudo --stdin shutdown --poweroff now"
  memory               = 2048
  disk_size            = "30G"
  ssh_timeout          = "20m"
  ssh_pty              = true

  http_content = {
    "/preseed.cfg" = templatefile(local.preseed_tpl_file, {
      password = var.encrypted_ssh_password
    })
    "/authorized_keys" = join(
      "",
      [
        file("${path.root}/playbooks/ssh_keys/id_rsa_ron.pub"),
        file("${path.root}/playbooks/ssh_keys/id_rsa_roxanne.pub")
      ]
    ),
    "/late_commands" = file("${path.root}/scripts/late_commands")
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

  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get upgrade --assume-yes"
    ]
    execute_command = "chmod +x {{ .Path }}; echo '${var.ssh_password}' | sudo --stdin {{ .Vars }} {{ .Path }}"
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
  }

  post-processor "shell-local" {
    inline = [
      "mv --verbose \"./playbooks/packer/${source.type}-${source.name}/packer-${source.name}\" \"./playbooks/packer/${source.type}-${source.name}/${source.name}.qcow2\""
    ]
  }
}
