# Infrastructure Design Documentation

## Architecture

- The following are the subnets for my homelab. Notes on this can be found
  [in its associated Trello card](https://trello.com/c/nUrXxJIE/119-decide-on-network-subnet-prefixes-for-staging-and-production-environments).
  - `192.168.0.x/24` -> production homelab network
  - `192.168.1.x/24` -> production Kubernetes cluster network
  - `192.168.1.x/24` -> staging homelab network
  - `192.168.2.x/24` -> staging Kubernetes cluster network
  - `192.168.3.x/24` -> staging management (mgmt) network
  - `192.168.4.x/24` -> staging VPN network

- The Linux distributions of choice should be community lead distributions. The
  preference on this comes from
  [in its associated Trello card](https://trello.com/c/mQ95baA5/164-migrate-kubernetes-cluster-poseidon-nodes-back-to-using-debian-12-instead-of-ubuntu-2204).

- The decision to use the `systemd-networkd` role came at the beginning when
  needing to set static network configurations for hosts and wanting to utilize
  `systemd` services more heavily. Notes concerning this can be found
  [in its associated Trello card](https://trello.com/c/NJPE8TxD/167-fix-virtual-nics-to-use-dhcp-in-the-packer-machine-images-when-first-booted-by-vms?search_id=784cfe32-2da0-431e-b3fe-54fab20c1c7b).

- The primary homelab network's DHCP and DNS needs should be satisfied by
  `dnsmasq`. Notes on this can be found
  [in its associated Trello card](https://trello.com/c/7WkUytTf/31-integrate-dnsmasq-for-dhcp-and-dns-into-my-project).

- The primary homelab network's load balancing needs should be satisfied by
  `haproxy`. Notes on this can be found
  [in its associated Trello card](https://trello.com/c/1irPAunK/41-integrate-haproxy-into-my-kubernetes-cluster-homelab-subnet).

- The primary homelab network's HTTPS MITM proxy needs should be satisfied by
  `mitmproxy`. Notes on this can be found
  [in its associated Trello card](https://trello.com/c/VDJYXYzf/251-integrate-a-self-hosted-kiwix-into-the-project).

- There will be a single QEMU/KVM host that will host my virtual machines. Notes
  on this can be found
  [in its associated Trello card](https://trello.com/c/uUa3Totk/127-create-the-kvm-playbook-to-provision-a-machine-to-run-kvm-and-libvirt).

- There will be a NFS server that will satisfy my shared storage needs. Notes on
  this can be found
  [in its associated Trello card](https://trello.com/c/EtZw0Kh4/252-integrate-a-nfs-server-into-the-project).

- Securely accessing my primary homelab network wherever I might should be
  satisfied by `WireGuard`. Notes on this can be found
  [in its associated Trello card](https://trello.com/c/6OfwfuPT/260-integrate-a-vpn-server-into-the-project).

- For my container orchestration needs, Kubernetes will be used. Notes on this
  can be found [in its associated Trello card](https://trello.com/c/HNzibsk1).

- The intended Ansible controllers will be my development machines.
  - It is known that there are secrets that will be exposed in Ansible output,
    but this isn't a concern due to the Ansible controllers being my development
    machines. Any logs uploaded elsewhere are vetted carefully for secrets. Task
    output is crucial for debugging, making `no_log` undesirable.

## Maintenance

- Follow these instructions for updating system packages across all hosts:
  1.  Run the `maintenance.yml` playbook.
