# Code Design Documentation

## Architecture

- The directory structure follows what is recommended by ansible-lint
  <https://ansible.readthedocs.io/projects/lint/usage/#linting-playbooks-and-roles>.

- The `site.yml` playbook serves as the main playbook that defines my homelab
  infrastructure. Below are a few additional playbooks that are worth
  mentioning.
  - The `on_prem.yml` playbook aggregates common configurations for my on
    premises hosts.

  - The `vagrant_customizations.yml` playbook modifies Vagrant provided hosts to
    be mostly comparable to production hosts. This playbook should be ran before
    running the `site.yml` playbook.

- The `ansible` groups have been defined based mostly on their associated
  function. The rest are defined (loosely) based on geography.
  - This decision was originally based on
    <https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html#how-to-differentiate-staging-vs-production>
    but such documentation has superseded by
    <https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html#group-inventory-by-function>.

  - The `ansible` groups are listed in order of most generic to specific within
    the inventory files, this includes when defining group variables.

- Local `ansible` roles are not intended to invoke each other. Also, instead of
  relying on roles dependency's mechanism, `requirements.yml` is used at the top
  level to define dependencies required by the local roles.

### Vagrant

> It should be noted when spinning up the staging/vagrant environment that the
> last host within the `ansible_host_vars` variable will not receive its
> management network IP address. Current theory on this is that this is due to
> Ruby's lazy loading (see b349d3b).

- `vagrant` is assumed to be installed from HashiCorp's package repositories.

- The `Vagrantfile` was written in a similar fashion as
  <https://developer.hashicorp.com/vagrant/docs/provisioning/ansible#ansible-parallel-execution>
  to take advantage of Ansible's parallelism.

- The primary hypervisor used to spin up the staging/vagrant environment will be
  QEMU/KVM along with the `vagrant-libvirt` plugin.

- The top level `vagrant_ansible_vars.json` was written to aggregate `ansible`
  host variables and `ansible` groups. A scaled back version of this
  [file exists within the project](../examples/vagrant_ansible_vars.json). Below
  will be a brief outline of some elements that are not self-explanatory.
  - `vagrant_config_refs` represent host variables whose value is defined by
    other host variables within the same host.
  - `vms_include` represent hosts that will be targeted when running `vagrant`
    commands.

## Conventions

- [Group package installations based on the need.](../examples/playbooks/append_distro_specificness.yml)
- [Put templates for use with ansible.builtin.template tasks within the 'templates' directory.](../examples/playbooks/utilize_relative_path_searching.yml)
- [Put files for use with ansible.builtin.copy tasks within the 'files' directory.](../examples/playbooks/utilize_relative_path_searching.yml)
- [Put files for use with the play's vars_files keyword within the 'vars' directory.](../examples/playbooks/utilize_relative_path_searching.yml)
- [Append the ansible_managed variable in files that are long-lived on a system.](../examples/playbooks/templates/foo.conf.j2)
- [Use `./` in file paths.](../examples/playbooks/use_keywords_order_plays.yml)
- Add brief comments on roles' defaults variables that are not self-explanatory.
- Do not use task parameter aliases (e.g.
  [ansible.builtin.apt's pkg parameter](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html#ansible-collections-ansible-builtin-apt-module-parameter-pkg)).
- Set the `state` parameter to a task module if such parameter exists.
- Append a environment prefix of `dev`, `staging`, or `prod` to Jinja templates
  that are meant for a particular environment.
  - `staging-dnsmasq-dhcp.conf.j2`
- Consider the following hierarchy (in decreasing granularity) when creating new
  variables to use. This hierarchy is derived from
  [an associated Trello card](https://trello.com/c/PYAlPypV/37-check-the-consistency-of-variable-values-being-passed-into-ansible-roles).
  1. Host variables in the inventory file.
  2. Group variables in the inventory file.
  3. Group variables file within the project.
  4. Role invocation using `vars:` parameters within the project (e.g.
     playbook).

- Follow this precedence when naming playbooks (an exception to this would be
  those under `./examples/playbooks`). This precedence is derived from
  [an associated Trello card](https://trello.com/c/zfi9zgsR/83-integrate-installing-haproxy-and-keepalived-from-poseidonk8scontrollers-into-loadbalancersyml).
  1. A playbook directly maps to a host's higher purpose via machine hostname
     (e.g. `vmms.yml` -> `vmm1`).
  2. A playbook indirectly maps to a host's higher purpose via `ansible` groups
     (e.g. `load_balancers.yml` -> `staging-node1`).
  3. A playbook does not map to a host's higher purpose (e.g.
     `vagrant_customizations.yml`).

## Maintenance

- Update software versions in `k8s_apps_versions.yml` when Kubernetes
  infrastructure patching occurs, as mentioned
  [the Infrastructure Design Documentation](./infrastructure.md).

- Update dependencies accordingly using Renovate.

- Update language runtime versions periodically.
  - Ruby is updated indirectly by upgrading the `vagrant` package from
    HashiCorp's package repositories.

  - Node and Python will have assistance from Renovate when updating.

- Create new TLS certificates as those expire.
  - Follow these instructions for the client TLS certificates related to IRC
    server identification.
    - For Libra.Chat:
      1. [Replace a IRC server's TLS certificate by creating a new one.](https://libera.chat/guides/certfp#creating-a-self-signed-certificate)
         The following can also be used
         `openssl req -x509 -new -nodes -sha256 -newkey "ed25519" -days 1096 -out "./playbooks/files/certs/liberachat.pem" -keyout "./playbooks/files/certs/liberachat.pem"`.
      2. Create/change calendar reminder for when the TLS certificate expires.
      3. Remove the fingerprint of the previous certificate stored by `NickServ`
         using `/msg NickServ CERT DELETE <fingerprint>`.
      4. Upload the new TLS certificate by running the `irc_clients.yml`
         playbook.
      5. [Get the fingerprint of the new TLS certificate.](https://libera.chat/guides/certfp#inspecting-your-certificate)
         The following can also be used
         `openssl x509 -noout -fingerprint -sha512 -in "./playbooks/files/certs/liberachat.pem" | awk -F "=" '{ gsub(":", ""); print tolower ($2) }'`.
      6. Add the fingerprint of the new certificate to `NickServ` using
         `/msg NickServ CERT ADD <fingerprint>`.
      7. Upload the new certificate to Bitwarden.

    - For OFTC:
      1. [Replace a IRC server's TLS certificate by creating a new one.](https://libera.chat/guides/certfp#creating-a-self-signed-certificate)
         The following can also be used
         `openssl req -x509 -new -nodes -sha256 -newkey "ed25519" -days 1096 -out "./playbooks/files/certs/oftc.pem" -keyout "./playbooks/files/certs/oftc.pem"`.
      2. Create/change calendar reminder for when the TLS certificate expires.
      3. Remove the fingerprint of the previous certificate stored by `NickServ`
         using `/msg NickServ CERT DEL <fingerprint>`.
      4. Upload the new TLS certificate by running the `irc_clients.yml`
         playbook.
      5. Disconnect and reconnect to the server, find an output line that looks
         like `Your client certificate fingerprint is <fingerprint>`.
      6. Add the fingerprint of the new certificate to `NickServ` using
         `/msg NickServ CERT ADD <fingerprint>`.
      7. Upload the new certificate to Bitwarden.
