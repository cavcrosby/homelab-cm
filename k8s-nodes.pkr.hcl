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
  iso_url              = "https://releases.ubuntu.com/22.04/ubuntu-22.04.2-live-server-amd64.iso"
  iso_checksum         = "sha256:5e38b55d57d94ff029719342357325ed3bda38fa80054f9330dc789cd2d43931"
  ssh_username         = "ansible"
  ssh_private_key_file = "~/.ssh/id_rsa"
  user_data_tpl_file   = "${path.root}/autoinstall.pkrtpl.hcl"
  boot_command = [
    "<tab><wait>",
    "c<wait>",
    "linux /casper/vmlinuz autoinstall quiet ",
    "ds='nocloud-net;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]
}

source "qemu" "poseidon_k8s_controller" {
  iso_url              = local.iso_url
  iso_checksum         = local.iso_checksum
  output_directory     = "./packer/qemu-poseidon_k8s_controller"
  format               = "qcow2"
  ssh_username         = local.ssh_username
  ssh_private_key_file = local.ssh_private_key_file
  shutdown_command     = "echo '${var.ssh_password}' | sudo --stdin shutdown --poweroff now"
  memory               = 2048
  disk_size            = "20G"
  ssh_timeout          = "20m"
  ssh_pty              = true

  http_content = {
    "/user-data" = templatefile(local.user_data_tpl_file, {
      password = var.encrypted_ssh_password
    })
    "/meta-data" = ""
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
  output_directory     = "./packer/qemu-poseidon_k8s_worker"
  format               = "qcow2"
  ssh_username         = local.ssh_username
  ssh_private_key_file = local.ssh_private_key_file
  shutdown_command     = "echo '${var.ssh_password}' | sudo --stdin shutdown --poweroff now"
  memory               = 2048
  disk_size            = "30G"
  ssh_timeout          = "20m"
  ssh_pty              = true

  http_content = {
    "/user-data" = templatefile(local.user_data_tpl_file, {
      password = var.encrypted_ssh_password
    })
    "/meta-data" = ""
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
      "cloud-init status --wait",
      "apt-get update && apt-get upgrade --assume-yes"
    ]
    execute_command = "chmod +x {{ .Path }}; echo '${var.ssh_password}' | sudo --stdin {{ .Vars }} {{ .Path }}"
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
  }

  post-processor "shell-local" {
    inline = [
      "mv --verbose \"./packer/${source.type}-${source.name}/packer-${source.name}\" \"./packer/${source.type}-${source.name}/${source.name}.qcow2\""
    ]
  }
}
