packer {
  required_plugins {
    qemu = {
      version = "= 1.0.9"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

locals {
  libvirt_output_dir_path = "./packer/libvirt-xcp-ng/output"
}

source "qemu" "xcp_ng" {
  iso_url          = "file://${path.cwd}/xcp-ng.iso"
  iso_checksum     = "file:file://${path.cwd}/xcp-ng.iso.sum"
  output_directory = local.libvirt_output_dir_path
  ssh_username     = "root"
  ssh_password     = "vagrant"
  shutdown_command = "shutdown --poweroff now"
  memory           = 2048
  disk_size        = "46G"
  ssh_timeout      = "20m"

  qemuargs = [
    [
      "-smp", "cpus=1"
    ],
  ]
}

build {
  sources = [
    "source.qemu.xcp_ng"
  ]

  provisioner "ansible" {
    playbook_file = "./playbooks/kvm_vagrant_boxes.yml"
    user          = "root"

    extra_arguments = [
      "-v"
    ]

    # MONITOR(cavcrosby): the signature algorithm used by the ansible provisioner is not
    # supported by OpenSSH starting at version 8.8, hence this workaround. For
    # reference on said issue and workaround:
    # https://github.com/hashicorp/packer-plugin-ansible/issues/69
    ansible_ssh_extra_args = [
      "-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa"
    ]

    ansible_env_vars = [
      "ANSIBLE_NOCOWS=true"
    ]
  }

  post-processor "shell-local" {
    inline = [
      "mv --verbose ${local.libvirt_output_dir_path}/packer-${source.name} ${local.libvirt_output_dir_path}/box.img"
    ]
  }
}
