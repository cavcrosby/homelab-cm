# Infrastructure Design Documentation

## Architecture

- The following are the subnets for my homelab. Notes on this can be found
  [here](https://trello.com/c/nUrXxJIE/119-decide-on-network-subnet-prefixes-for-staging-and-production-environments).

  - `192.168.0.x/24` -> production homelab network
  - `192.168.1.x/24` -> production Kubernetes cluster (Poseidon) network
  - `192.168.1.x/24` -> staging homelab network
  - `192.168.2.x/24` -> staging Kubernetes cluster (Poseidon) network
  - `192.168.3.x/24` -> staging management (mgmt) network
  - `192.168.4.x/24` -> staging VPN network

- The Linux distributions of choice should be community lead distributions. The
  preference on this comes from
  [here](https://trello.com/c/mQ95baA5/164-migrate-kubernetes-cluster-poseidon-nodes-back-to-using-debian-12-instead-of-ubuntu-2204).

- The decision to use the `systemd-networkd` role came at the beginning when
  needing to set static network configurations for hosts and wanting to utilize
  `systemd` services more heavily. Notes concerning this can be found
  [here](https://trello.com/c/NJPE8TxD/167-fix-virtual-nics-to-use-dhcp-in-the-packer-machine-images-when-first-booted-by-vms?search_id=784cfe32-2da0-431e-b3fe-54fab20c1c7b).

- The primary homelab network's DHCP and DNS needs should be satisfied by
  `dnsmasq`. Notes on this can be found
  [here](https://trello.com/c/7WkUytTf/31-integrate-dnsmasq-for-dhcp-and-dns-into-my-project).

- The primary homelab network's load balancing needs should be satisfied by
  `haproxy`. Notes on this can be found
  [here](https://trello.com/c/1irPAunK/41-integrate-haproxy-into-my-kubernetes-cluster-homelab-subnet).

- The primary homelab network's HTTPS MITM proxy needs should be satisfied by
  `mitmproxy`. Notes on this can be found
  [here](https://trello.com/c/VDJYXYzf/251-integrate-a-self-hosted-kiwix-into-the-project).

- There will be a single QEMU/KVM host that will host my virtual machines. Notes
  on this can be found
  [here](https://trello.com/c/uUa3Totk/127-create-the-kvm-playbook-to-provision-a-machine-to-run-kvm-and-libvirt).

- There will be a NFS server that will satisfy my shared storage needs. Notes on
  this can be found
  [here](https://trello.com/c/EtZw0Kh4/252-integrate-a-nfs-server-into-the-project).

- Securely accessing my primary homelab network wherever I might should be
  satisfied by `WireGuard`. Notes on this can be found
  [here](https://trello.com/c/6OfwfuPT/260-integrate-a-vpn-server-into-the-project).

- The Kubernetes cluster (Poseidon) has reasons for each part of the
  configuration set.

  - [High Availability Configuration](https://trello.com/c/8JopdDFW/48-achieve-highly-available-for-my-kubernetes-cluster?search_id=05ef3726-02cf-4c28-a93c-6ad6c1e0136b)
  - [containerd](https://trello.com/c/0fXGhRc5/8-cluster-ctrserver1-and-ctrserver2s-docker-daemons)
  - [Calico CNI](https://trello.com/c/iRX5bxkG/49-integrate-calico-into-my-kubernetes-cluster)
  - [Ingress NGINX Controller](https://trello.com/c/Gfe7zpEG/45-add-an-ingress-controller-to-my-kubernetes-cluster)
  - [Metrics Server](https://trello.com/c/iOulE53j/108-integrate-the-metrics-server-into-my-kubernetes-cluster-poseidon)
  - [HAProxy](https://trello.com/c/ctaRjPU7/40-integrate-haproxy-into-my-kubernetes-cluster-k8s-cluster-subnet)
  - [keepalived](https://trello.com/c/5hnN6ke6/78-reconsider-load-balancer-configuration-and-architecture-used-to-distribute-traffic-between-the-kubernetes-api-servers?search_id=f79767ea-223f-43fa-82c3-843a1ebf671c)

- The intended Ansible controllers will be my development machines.

  - It is known that there are secrets that will be exposed in Ansible output,
    but this isn't a concern due to the Ansible controllers being my development
    machines. Any logs uploaded elsewhere are vetted carefully for secrets. Task
    output is crucial for debugging, making `no_log` undesirable.

## Maintenance

- [Follow these notes to have a Kubernetes node join an already existing Kubernetes cluster (Poseidon).](https://trello.com/c/HO0aWCED/95-look-into-how-to-handle-a-worker-or-controller-rejoining-the-kubernetes-cluster-poseidon-after-the-cluster-has-been-created)

- Follow these instructions for updating system packages across all hosts:

  1.  Run the `maintenance.yml` playbook.

- Follow these instructions for checking load balancer backends:

  1.  Run the `maintenance.yml` playbook.

- Follow these instructions for upgrading an instance of the Kubernetes cluster
  (Poseidon). This presumes the cluster is running at least on version `v1.28`.

  - If upgrading from version `1.28.x` to version `1.28.y` (where `y > x`):

    1. Update `./playbooks/vars/poseidon_k8s_software_versions.yml` accordingly.
    2. Update `./playbooks/tasks/setup_calico.yml` accordingly.
    3. Run the `maintenance.yml` playbook.

  - If upgrading from version `1.28.x` to version `1.29.x`:

    1. Update `./playbooks/vars/poseidon_k8s_software_versions.yml` accordingly.
    2. Update `./playbooks/tasks/setup_calico.yml` accordingly.
    3. Update the `maintenance.yml` playbook according the
       [official documentation](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade)
       for any changes in the upgrading process.
    4. Run the `maintenance.yml` playbook.

  - If upgrading from version `1.x` to version `1.y` (where
    `y > x and (y-x) > 1`):

    1. Update `./playbooks/vars/poseidon_k8s_software_versions.yml` accordingly.
    2. Update `./playbooks/tasks/setup_calico.yml` accordingly.
    3. Update the `maintenance.yml` playbook according the
       [official documentation](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade)
       for any changes in the upgrading process.
    4. Tear down and redeploy the cluster.
