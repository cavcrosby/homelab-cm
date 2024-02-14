# Code Design Documentation

## Architecture

- The directory structure follows what is recommended by ansible-lint
  <https://ansible.readthedocs.io/projects/lint/usage/#linting-playbooks-and-roles>.

- The `site.yml` playbook serves as the main playbook that defines my homelab
  infrastructure. Below are a few additional playbooks that are worth
  mentioning.

  - The `on_prem.yml` playbook aggregates common configurations for my on
    premises hosts. This playbook should be ran before others in the `site.yml`
    playbook.

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

- The Kubernetes (`k8s`) playbooks are structured to run a generic play first
  then a named configuration play second. The notes on these decisions can be
  found
  [here](https://trello.com/c/QcvcMHUW/59-refactor-k8s-related-playbooks-ansible-units-in-assuming-there-only-exist-one-cluster).

  - For example, the `Setup Kubernetes control planes (first control-planes)`
    play runs before the
    `Setup Kubernetes control planes (first control-planes) (poseidon)` play.

  - Each Kubernetes named configuration set (e.g. `poseidon`) will have its
    templates stored in a subdirectory under `./playbooks/templates`.

- Local `ansible` roles are not intended to invoke each other. Also, instead of
  relying on roles dependency's mechanism, `requirements.yml` is used at the top
  level to define dependencies required by the local roles.

### Vagrant

> It should be noted when spinning up the staging/vagrant environment that the
> last host within the `ansible_host_vars` variable will not receive its
> `mgmt-homelab-cm` IP address. Current theory on this is that this is due to
> Ruby's lazy loading (see b349d3b).

- `vagrant` is assumed to be installed from HashiCorp's package repositories.

- The `Vagrantfile` was written in a similar fashion as
  <https://developer.hashicorp.com/vagrant/docs/provisioning/ansible#ansible-parallel-execution>
  to take advantage of Ansible's parallelism.

- The primary hypervisor used to spin up the staging/vagrant environment will be
  QEMU/KVM along with the `vagrant-libvirt` plugin.

- The top level `vagrant_ansible_vars.json` was written to aggregate `ansible`
  host variables and `ansible` groups. A scaled back version of this file can be
  found [here](../examples/vagrant_ansible_vars.json). Below will be a brief
  outline of some elements that are not self-explanatory.
  - `vagrant_config_refs` represent host variables whose value is defined by
    other host variables within the same host.
  - `vagrant_external_config_refs` represent host variables whose value is
    defined by other host variables within a different host.
  - `vms_include` represent hosts that will be targeted when running `vagrant`
    commands.

## Conventions

- [Set the errexit and pipefail options for ansible.builtin.shell tasks (bash).](../examples/playbooks/set_errexit_pipefail.yml)
- [Single quote regular expression or glob patterns.](../examples/playbooks/single_quote_patterns.yml)
- [Do not use abbreviations in task names.](../examples/playbooks/single_quote_patterns.yml)
  - Notice how distribution was used instead of distro.
- [Double quote octal numbers to the mode parameter.](../examples/playbooks/double_quote_modes.yml)
- [Use 'system user' verbiage only for operating system system-level user accounts.](../examples/playbooks/use_system_user_verbiage.yml)
- [Be direct when possible when referring to operating system users in task names.](../examples/playbooks/use_system_user_verbiage.yml)
  - Referring to the `ansible_user` is an exception.
- [Append distribution specificness to tasks where appropriate.](../examples/playbooks/append_distro_specificness.yml)
- [List package names to task parameters in alphabetical order.](../examples/playbooks/append_distro_specificness.yml)
- [Group package installations based on the need.](../examples/playbooks/append_distro_specificness.yml)
- [Utilize the local relative path searching when specifying the src parameter to ansible.builtin.template tasks.](../examples/playbooks/utilize_tpl_searching_controller.yml)
- [Prefix all `ansible` tags with a verb.](../examples/playbooks/utilize_tpl_searching_controller.yml)
- [Append the ansible_managed macro in files that are long-lived on a system.](../examples/playbooks/templates/foo.conf.j2)
- [Use fully qualified collection names for `ansible` filters.](../examples/playbooks/use_fqcn_filters.yml)
- [Use the following order of `ansible` playbook keywords in a task.](../examples/playbooks/use_keywords_order_tasks.yml)
- [Use yaml lists for the `notify`, and `when` playbook keywords only when there is more than one element.](../examples/playbooks/use_keywords_order_tasks.yml)
- [Use the following order of `ansible` playbook keywords in a play.](../examples/playbooks/use_keywords_order_plays.yml)
- [Use `./` in file paths.](../examples/playbooks/use_keywords_order_plays.yml)
- [Set the `checksum` parameter in ansible.builtin.get_url tasks.](../examples/playbooks/set_checksum_get_url.yml)
- [Use the following approach for ansible.builtin.shell and ansible.builtin.command tasks when ansible-lint throws a no-changed-when violation.](https://github.com/cavcrosby/homelab-cm/commit/d627eea3e3a83a53b49a9a9ffd19a94ecb48a4ce#diff-efab1825780e85320dbe39224b50a732d7eb301dfcc935d85816b8e77b7e2e36)
- [In general, do not use quotes in the `ansible` yaml.](https://stackoverflow.com/questions/19109912/yaml-do-i-need-quotes-for-strings-in-yaml#answer-22235064)
- Append a file extension of '.yml' to all `ansible` yaml files.
- Do not use dashes in `ansible` yaml's file names, instead use underscores.
- Do not use underscores in Jinja template's file names, instead use dashes.
  - The `libvirt_default_uri.j2` and `pam_access.conf.j2` templates are
    exceptions.
- Append playbook plays with at least one tag.
- Follow the indentation used through the codebase for all `ansible` yaml.
- Add brief comments on roles' defaults variables that are not self-explanatory.
- Do not use task parameter aliases (e.g.
  [ansible.builtin.apt's pkg parameter](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html#ansible-collections-ansible-builtin-apt-module-parameter-pkg)).
- Set the `state` parameter to a task module if such parameter exists.
- Do not include variables as part of a task's name.
  - `ansible-lint` (see
    [name[template]](https://ansible.readthedocs.io/projects/lint/rules/name/))
    only discourages the use of variables in task names but I'm outright
    avoiding such usage.
- Append a environment prefix of `dev`, `staging`, or `prod` to Jinja templates
  that are meant for a particular environment.
  - `staging-dnsmasq-dhcp.conf.j2`
- Consider the following hierarchy (in decreasing granularity) when creating new
  variables to use. This hierarchy is derived from
  [here](https://trello.com/c/PYAlPypV/37-check-the-consistency-of-variable-values-being-passed-into-ansible-roles).

  1. Host variables in the inventory file.
  2. Group variables in the inventory file.
  3. Group variables file within the project.
  4. Role invocation using `vars:` parameters within the project (e.g.
     playbook).

- Follow this precedence when naming playbooks (an exception to this would be
  those under `./examples/playbooks`). This precedence is derived from
  [here](https://trello.com/c/zfi9zgsR/83-integrate-installing-haproxy-and-keepalived-from-poseidonk8scontrollers-into-loadbalancersyml).

  1. A playbook directly maps to a host's higher purpose via machine hostname
     (e.g. `k8s_controllers.yml` -> `poseidon-k8s-controller1`).
  2. A playbook indirectly maps to a host's higher purpose via `ansible` groups
     (e.g. `load_balancers.yml` -> `staging-node1`).
  3. A playbook does not map to a host's higher purpose (e.g.
     `vagrant_customizations.yml`).

## Maintenance

- Update software versions in `poseidon_k8s_software_versions.yml` when
  Kubernetes infrastructure patching occurs, as mentioned
  [here](./infrastructure.md).

- Update dependencies accordingly using Renovate.

- Update `VAGRANT_UPSTREAM_VERSION` periodically to newer versions of `vagrant`
  as they come out.

- Update language runtime versions periodically.

  - Ruby is updated indirectly by upgrading the `vagrant` package from
    HashiCorp's package repositories.

  - Node will have assistance from Renovate when updating. Whereas Python does
    not.

- Update `required_version` of `packer` and `required_plugins` for `packer`
  periodically.

- [Use the following procedure when updating public GPG key checksums.](https://trello.com/c/8IaHDWO7/151-create-a-process-to-verify-public-gpg-keys-upon-updating-related-ansible-tasks-checksum)

- Create new TLS certificates as those expire.

  - [Follow these instructions to create a certificate for the root CA.](https://kubernetes.io/docs/tasks/administer-cluster/certificates/#openssl)

    - The Common Name (CN) should be set to 'Conner Crosby (homelab-cm)'.

    - The following can also be used to generate the signing key and certificate
      respectively
      `openssl genrsa -out "./playbooks/rsa_keys/poseidon_k8s_ca.key" 2048` and
      `openssl req -x509 -new -nodes -key "./playbooks/rsa_keys/poseidon_k8s_ca.key" -subj "/CN=Conner Crosby (homelab-cm)" -days 10000 -out "./playbooks/certs/poseidon_k8s_ca.crt"`.

  - Follow these instructions for the client TLS certificates related to IRC
    server identification.

    - For Libra.Chat:

      1. [Replace a IRC server's TLS certificate by creating a new one.](https://libera.chat/guides/certfp#creating-a-self-signed-certificate)
         The following can also be used
         `openssl req -x509 -new -nodes -sha256 -newkey "ed25519" -days 1096 -out "./playbooks/certs/liberachat.pem" -keyout "./playbooks/certs/liberachat.pem"`.
      2. Create/change calendar reminder for when the TLS certificate expires.
      3. Remove the fingerprint of the previous certificate stored by `NickServ`
         using `/msg NickServ CERT DELETE <fingerprint>`.
      4. Upload the new TLS certificate by running the `irc_clients.yml`
         playbook.
      5. [Get the fingerprint of the new TLS certificate.](https://libera.chat/guides/certfp#inspecting-your-certificate)
         The following can also be used
         `openssl x509 -noout -fingerprint -sha512 -in "./playbooks/certs/liberachat.pem" | awk -F "=" '{ gsub(":", ""); print tolower ($2) }'`.
      6. Add the fingerprint of the new certificate to `NickServ` using
         `/msg NickServ CERT ADD <fingerprint>`.
      7. Upload the new certificate to Bitwarden.

    - For OFTC:

      1. [Replace a IRC server's TLS certificate by creating a new one.](https://libera.chat/guides/certfp#creating-a-self-signed-certificate)
         The following can also be used
         `openssl req -x509 -new -nodes -sha256 -newkey "ed25519" -days 1096 -out "./playbooks/certs/oftc.pem" -keyout "./playbooks/certs/oftc.pem"`.
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
