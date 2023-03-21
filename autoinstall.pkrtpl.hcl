#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: us
  apt:
    primary:
      - arches:
          - amd64
        uri: http://archive.ubuntu.com/ubuntu
    security:
      - arches:
          - amd64
        uri: http://archive.ubuntu.com/ubuntu
  storage:
    layout:
      name: direct
  user-data:
    hostname: ansible-client
    groups:
      - ansible
    users:
      - name: ansible
        primary_group: ansible
        passwd: ${password}
        gecos: Red Hat Ansible
        shell: /bin/bash
        lock_passwd: false
        ssh_authorized_keys:
          - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDMFp/vRs9ZExBv6Lux1AvyYPUcPhmrw/rFKHhVwNGVtnMATXvEMnU89KPp4r93clCyIT4IXoiKSBdV0OkGDe0b1LMtCOxhChYsJdzpXS2hJH5gjom5u3Uab99ZSuDhbHQja/h05qlY04vYD3cnsK9u2C3Tkyw6ShHyFEIViWQB7WXhkFsrskUNp2ZwtcLmrMCaoZhDgpWSa9JuE7CLBv+PwNi/r+x/uuJuQVTOCXDa20ogIVuH8CbzbYRdPJUzbpDgs3pvt9mHVK4U5GFfq3zh73SvkKm2gj0mloYCMEJD9RE2OjWaNPHeBio175hsgYu0oPF3WilU/9Cg7NTW646jjnl5Pu4izWvjaUeZjNgr697D4S80rSl3gpMT5dkR2WH4/bLF6EEGh2Fkl6wXlrcMe8pu53p3o1nHAVjUbfcRyoson/fUf3/OLOeqdbEWt0DgvFKCsqVXUgLpH/68bdOvsA/7M/BbGDoxwDlJdZWiuakN5Oun9PKiq1bnQh41+Ck= conner@Ron
          - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC0CWc4hR42WPV3faQNMcC7r4ZDpUQLUdtDAQa70/LtTKrOrl/QrclcM2s3oHwm+24IIs4LyJhY3w+2ZGM08pM72VpZVegd15QVdg/bbKsk+e7afa45GwJ3YkYKdOW62S41LuUg695OEVuwl9lCHh4PpPYTTxMI2wlTKKLweXYTnDSf3TgMnAbT0jV4afI+lSlPgj4EDog/wYe7rrbPdX7ATXMMU9h8a1SnhQ6nEwsXM4JRvmW7TLFcl82l7P7rZdI0vQ0vGMwXp/ZhgZ1e2cMKtSdRANpf+BvvpRgfZqAW/IKB+S2jOIHfeVZA+vDKr430Eq0Qg7wUFEZ1RPCJupicYthtlb56iMPcd182JgGOalMhWtuMzFsB6l2HWxBoSqe1RpjEx1Qz9aydHRgnwMSofu8TG62bbcy6B3O4Gsw+3obslloJLJwaXAquyEEFlwUrLjrAxGAjnpXT9+tJsi9yF8MrROg8M9V4PJdqkDlV7xofkkAtziOnBgoV77eENYc= conner@Roxanne
  ssh:
    install-server: yes
    allow-pw: false
  late-commands:
    - curtin in-target -- /bin/sh -c 'echo "Defaults:ansible !requiretty" > /etc/sudoers.d/ansible'
    - curtin in-target -- /bin/sh -c 'echo "ansible ALL=(ALL) ALL" >> /etc/sudoers.d/ansible'
