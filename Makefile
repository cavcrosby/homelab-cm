# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursively expanded variables
SHELL = /usr/bin/sh
TRUTHY_VALUES = \
    true\
    1

ANSIBLE_SECRETS_DIR_PATH = ./playbooks/vars
ANSIBLE_SECRETS_FILE = ansible_secrets.yml
ANSIBLE_SECRETS_FILE_PATH = ${ANSIBLE_SECRETS_DIR_PATH}/${ANSIBLE_SECRETS_FILE}
BITWARDEN_ANSIBLE_SECRETS_ITEMID = a50012a3-3685-454c-b480-adf300ec834c

BITWARDEN_RSA_KEYS_DIR_PATH = ./playbooks/files/rsa_keys
BITWARDEN_RSA_KEYS_ITEMID = 0a2e75a3-7f1d-4720-ad05-aec2016c4ba9
BITWARDEN_RSA_KEYS = \
	poseidon_k8s_ca.key

BITWARDEN_TLS_CERTS_DIR_PATH = ./playbooks/files/certs
BITWARDEN_TLS_CERTS_ITEMID = 0857a42d-0d60-4ecc-8c43-ae200066a2b3
BITWARDEN_TLS_CERTS = \
	liberachat.pem\
	oftc.pem\
	poseidon_k8s_ca.crt

BITWARDEN_WIREGUARD_KEYS_DIR_PATH = ./playbooks/files
BITWARDEN_WIREGUARD_KEYS_ITEMID = e566965b-5509-4241-ab05-b30801168db3
BITWARDEN_WIREGUARD_KEYS = \
	gerald.wg0.key\
	staging-node1.wg0.key

export PROJECT_VAGRANT_CONFIGURATION_FILE = vagrant_ansible_vars.json
export ANSIBLE_CONFIG = ./ansible.cfg

# targets
HELP = help
SETUP = setup
INVENTORY = inventory
PRESEED_CFG = preseed.cfg
PRODUCTION = production
STAGING = staging
PRODUCTION_MAINTENANCE = production-maintenance
PRODUCTION_LOCALHOST = production-localhost
STAGING_MAINTENANCE = staging-maintenance
STAGING_LOCALHOST = staging-localhost
ANSIBLE_SECRETS = ansible-secrets
K8S_NODE_IMAGES = k8s-node-images
CONTAINERD_DEB = containerd-deb
EXAMPLES_TEST = examples-test
LINT = lint
FORMAT = format
DEVELOPMENT_SHELL = development-shell
CLEAN = clean

# ansible-secrets actions
PUT = put

# libvirt provider configurations
LIBVIRT = libvirt
export LIBVIRT_PREFIX = $(shell basename ${CURDIR})_

# to be (or can be) passed in at make runtime
VAGRANT_PROVIDER = ${LIBVIRT}
export USE_MAINTENANCE_PLAYBOOK =
export ANSIBLE_EXTRA_VARS =
export ANSIBLE_TAGS = all

# executables
ANSIBLE = ansible
ANSIBLE_GALAXY = ansible-galaxy
ANSIBLE_LINT = ansible-lint
ANSIBLE_PLAYBOOK = ansible-playbook
ANSIBLE_VAULT = ansible-vault
BASH = bash
VIRSH = virsh
VAGRANT = vagrant
PACKER = packer
BUNDLE = bundle
GEM = gem
PKILL = pkill
YQ = yq
BW = bw
PYTHON = python
PIP = pip
NPM = npm
NPX = npx
PRE_COMMIT = pre-commit
CURL = curl
MOLECULE = molecule
MARKDOWNLINT_CLI2 = markdownlint-cli2
PRETTIER = prettier

# simply expanded variables
executables := \
	${VIRSH}\
	${VAGRANT}\
	${PKILL}\
	${YQ}\
	${ANSIBLE_PLAYBOOK}\
	${ANSIBLE_GALAXY}\
	${ANSIBLE_LINT}\
	${ANSIBLE_VAULT}\
	${BUNDLE}\
	${GEM}\
	${BASH}\
	${PYTHON}\
	${NPM}\
	${PACKER}\
	${CURL}

_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))

# provider VM identifiers
VM_NAMES := $(shell ${YQ} '.ansible_host_vars | keys[]' < "${PROJECT_VAGRANT_CONFIGURATION_FILE}")
# include all VMs by default
VMS_INCLUDE := $(shell \
	${YQ} \
		'.vms_include[]? // (.ansible_host_vars | keys[])' \
		< "${PROJECT_VAGRANT_CONFIGURATION_FILE}" \
)

LIBVIRT_DOMAINS := $(shell \
	for vm_name in ${VM_NAMES}; do \
		if echo "${VMS_INCLUDE}" | grep --quiet "$${vm_name}"; then \
			echo "${LIBVIRT_PREFIX}$${vm_name}"; \
		fi; \
	done \
)

ifeq (${VAGRANT_PROVIDER},${LIBVIRT})
	ifneq ($(shell for domain in ${LIBVIRT_DOMAINS}; do ${VIRSH} list --all --name | head --lines -1 | grep "$${domain}"; done),)
		VMS_EXISTS := true
	endif
# else (${VAGRANT_PROVIDER},${VBOX})
# 	ifneq ($(code that determines if virtualbox VMs exist),)
# 		VMS_EXISTS=true
# 	endif
endif

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Common make targets:'
>	@echo '  ${SETUP}                - install the distro-independent dependencies for this'
>	@echo '                         project'
>	@echo '  ${INVENTORY}            - create the production inventory file'
>	@echo '  ${PRESEED_CFG}          - create the production preseed.cfg file'
>	@echo '  ${PRODUCTION}           - run the main playbook for my homelab'
>	@echo '  ${STAGING}              - run the main playbook for my homelab, but in a'
>	@echo '                         virtual environment setup by Vagrant'
>	@echo '  ${LINT}                 - lint the yaml configuration code, json configurations'
>	@echo '                         and markdown documentation'
>	@echo '  ${FORMAT}               - format the markdown documentation'
>	@echo '  ${EXAMPLES_TEST}        - test the example'\''s yaml configuration code'
>	@echo '  ${ANSIBLE_SECRETS}      - manage secrets used by this project, by default'
>	@echo '                         secrets are pulled into the project'
>	@echo '  ${DEVELOPMENT_SHELL}    - run a bash shell with make variables injected into'
>	@echo '                         it to work with the project'\''s Vagrantfile'
>	@echo '  ${CLEAN}                - remove files generated from targets'
>	@echo 'Common make configurations (e.g. make [config]=1 [targets]):'
>	@echo '  ANSIBLE_TAGS             - sets the tags denoting the tasks/roles/plays for'
>	@echo '                             Ansible to run (default: all)'
>	@echo '  VAGRANT_PROVIDER         - sets the provider used for the virtual environment'
>	@echo '                             created by Vagrant (default: libvirt)'
>	@echo '  ANSIBLE_VERBOSITY        - sets the verbosity level when running ansible commands,'
>	@echo '                             equivalent to the number of -v passed in the command line'
>	@echo '  ANSIBLE_SECRETS_ACTION   - determines the action to take concerning project'
>	@echo '                             secrets (options: put)'
>	@echo '  ANSIBLE_EXTRA_VARS       - passes variables into the ansible-playbook runtime, see'
>	@echo '                             --extra-vars documentation on argument format'
>	@echo '  ANSIBLE_LIMIT            - sets a pattern to further limit selected hosts, see'
>	@echo '                             --limit documentation on argument format'

.PHONY: ${SETUP}
${SETUP}:
>	@[ -n "${MITMPROXY_PYTHON_PATH}" ] \
		|| { echo "make: MITMPROXY_PYTHON_PATH was not passed into make"; exit 1; }

>	ln \
		--symbolic \
		--force \
		"${MITMPROXY_PYTHON_PATH}" \
		"./mitmproxy/bin/python"

>	ln \
		--symbolic \
		--force \
		--no-dereference \
		"${CURDIR}" \
		"$${HOME}/.local/src/homelab-cm"

>	./scripts/chk-vagrant-pkg
>	${BUNDLE} install
>	${VAGRANT} plugin install "$$(find ./vendor -name 'vagrant-libvirt-*.gem')"
>	${NPM} install
>	${PYTHON} -m ${PIP} install --upgrade "${PIP}"
>	${PYTHON} -m ${PIP} install \
		--requirement "./requirements.txt" \
		--requirement "./requirements-dev.txt"

>	${ANSIBLE_GALAXY} collection install \
		--requirements-file "./meta/requirements.yml" \
		--collections-path "./ansible/collections"

>	${PRE_COMMIT} install

.PHONY: ${INVENTORY}
${INVENTORY}:
>	${ANSIBLE} \
		--module-name "ansible.builtin.template" \
		--args 'src=./production.j2 dest=./production mode="644"' \
		--extra-vars "@./playbooks/vars/network_configs.yml" \
		"localhost"

${PRESEED_CFG}: ./preseed.cfg.j2
>	@[ -n "${DISK_ID}" ] \
		|| { echo "make: DISK_ID was not passed into make"; exit 1; }

>	@[ -n "${ENCRYPTED_ANSIBLE_USER_PASSWORD}" ] \
		|| { echo "make: ENCRYPTED_ANSIBLE_USER_PASSWORD was not passed into make"; exit 1; }

>	@[ -n "${ENCRYPTION_PASSPHRASE}" ] \
		|| { echo "make: ENCRYPTION_PASSPHRASE was not passed into make"; exit 1; }

>	${ANSIBLE} \
		--module-name "ansible.builtin.template" \
		--args 'src=$< dest=./$@ mode="644"' \
		--extra-vars '{"disk_id": "${DISK_ID}","encrypted_password":"$(value ENCRYPTED_ANSIBLE_USER_PASSWORD)","encryption_passphrase":"$(value ENCRYPTION_PASSPHRASE)","encrypt_disks":true,"for_vms":false}' \
		"localhost"

.PHONY: ${PRODUCTION}
${PRODUCTION}: export ANSIBLE_LOG_PATH = \
				./logs/ansible.log.prod-$(shell date "+%Y-%m-%dT%H:%M:%S-$$(uuidgen | head --bytes 5)")
${PRODUCTION}: ANSIBLE_PLAYBOOK_OPTIONS := --ask-become-pass\
				--inventory "production"\
				--tags "${ANSIBLE_TAGS}"\
				--extra-vars "network_configs_path=network_configs.yml k8s_software_versions_file=poseidon_k8s_software_versions.yml"
${PRODUCTION}: ANSIBLE_PLAYBOOK_OPTIONS += $(if ${ANSIBLE_LIMIT},--limit ${ANSIBLE_LIMIT},)
${PRODUCTION}: ANSIBLE_PLAYBOOK_OPTIONS += $(if ${ANSIBLE_EXTRA_VARS},--extra-vars ${ANSIBLE_EXTRA_VARS},)
${PRODUCTION}:
>	${ANSIBLE_PLAYBOOK} ${ANSIBLE_PLAYBOOK_OPTIONS} "./playbooks/site.yml"

.PHONY: ${STAGING}
${STAGING}: export ANSIBLE_LOG_PATH = \
				./logs/ansible.log.staging-$(shell date "+%Y-%m-%dT%H:%M:%S-$$(uuidgen | head --bytes 5)")
${STAGING}:
ifneq ($(findstring ${VMS_EXISTS},${TRUTHY_VALUES}),)
>	${VAGRANT} up \
		--provision \
		--no-destroy-on-error \
		--provider "${VAGRANT_PROVIDER}"
else
>	${VAGRANT} up --no-destroy-on-error --provider "${VAGRANT_PROVIDER}"
endif
>	sudo ./scripts/set-iptables-vpn

.PHONY: ${PRODUCTION_MAINTENANCE}
${PRODUCTION_MAINTENANCE}: export ANSIBLE_LOG_PATH = \
							./logs/ansible.log.prod-$(shell date "+%Y-%m-%dT%H:%M:%S-$$(uuidgen | head --bytes 5)")
${PRODUCTION_MAINTENANCE}: ANSIBLE_PLAYBOOK_OPTIONS := --ask-become-pass\
							--inventory "production"\
							--tags "${ANSIBLE_TAGS}"
${PRODUCTION_MAINTENANCE}: ANSIBLE_PLAYBOOK_OPTIONS += $(if ${ANSIBLE_LIMIT},--limit ${ANSIBLE_LIMIT},)
${PRODUCTION_MAINTENANCE}:
>	${ANSIBLE_PLAYBOOK} ${ANSIBLE_PLAYBOOK_OPTIONS} "./playbooks/maintenance.yml"

.PHONY: ${PRODUCTION_LOCALHOST}
${PRODUCTION_LOCALHOST}: export ANSIBLE_LOG_PATH = \
							./logs/ansible.log.prod-$(shell date "+%Y-%m-%dT%H:%M:%S-$$(uuidgen | head --bytes 5)")
${PRODUCTION_LOCALHOST}: ANSIBLE_PLAYBOOK_OPTIONS := --ask-become-pass\
							--inventory "production"\
							--tags "${ANSIBLE_TAGS}"\
							--extra-vars '{"wireguard_privkey_path":"${WIREGUARD_PRIVKEY_PATH}","wireguard_network_interface_name":"${WIREGUARD_NETWORK_INTERFACE_NAME}","associated_network_interface_type":"${ASSOCIATED_NETWORK_INTERFACE_TYPE}","associated_network_interface_name":"${ASSOCIATED_NETWORK_INTERFACE_NAME}","wireguard_server_pubkey":"${WIREGUARD_SERVER_PUBKEY}","network_configs_path":"./network_configs.yml","enable_dhcp":true}'
${PRODUCTION_LOCALHOST}:
>	@[ -n "${WIREGUARD_PRIVKEY_PATH}" ] \
		|| { echo "make: WIREGUARD_PRIVKEY_PATH was not passed into make"; exit 1; }

>	@[ -n "${WIREGUARD_NETWORK_INTERFACE_NAME}" ] \
		|| { echo "make: WIREGUARD_NETWORK_INTERFACE_NAME was not passed into make"; exit 1; }

>	@[ -n "${ASSOCIATED_NETWORK_INTERFACE_TYPE}" ] \
		|| { echo "make: ASSOCIATED_NETWORK_INTERFACE_TYPE was not passed into make"; exit 1; }

>	@[ -n "${ASSOCIATED_NETWORK_INTERFACE_NAME}" ] \
		|| { echo "make: ASSOCIATED_NETWORK_INTERFACE_NAME was not passed into make"; exit 1; }

>	@[ -n "${WIREGUARD_SERVER_PUBKEY}" ] \
		|| { echo "make: WIREGUARD_SERVER_PUBKEY was not passed into make"; exit 1; }

>	${ANSIBLE_PLAYBOOK} ${ANSIBLE_PLAYBOOK_OPTIONS} "./playbooks/localhost.yml"

.PHONY: ${STAGING_MAINTENANCE}
${STAGING_MAINTENANCE}:
>	${MAKE} USE_MAINTENANCE_PLAYBOOK="true" "${STAGING}"

.PHONY: ${STAGING_LOCALHOST}
${STAGING_LOCALHOST}:
>	@[ -n "${WIREGUARD_PRIVKEY_PATH}" ] \
		|| { echo "make: WIREGUARD_PRIVKEY_PATH was not passed into make"; exit 1; }

>	@[ -n "${WIREGUARD_NETWORK_INTERFACE_NAME}" ] \
		|| { echo "make: WIREGUARD_NETWORK_INTERFACE_NAME was not passed into make"; exit 1; }

>	@[ -n "${ASSOCIATED_NETWORK_INTERFACE_TYPE}" ] \
		|| { echo "make: ASSOCIATED_NETWORK_INTERFACE_TYPE was not passed into make"; exit 1; }

>	@[ -n "${ASSOCIATED_NETWORK_INTERFACE_NAME}" ] \
		|| { echo "make: ASSOCIATED_NETWORK_INTERFACE_NAME was not passed into make"; exit 1; }

>	@[ -n "${WIREGUARD_SERVER_PUBKEY}" ] \
		|| { echo "make: WIREGUARD_SERVER_PUBKEY was not passed into make"; exit 1; }

>	${MAKE} USE_LOCALHOST_PLAYBOOK="true" "${STAGING}"

.PHONY: ${LINT}
${LINT}:
>	@for fil in ${PROJECT_VAGRANT_CONFIGURATION_FILE} "./examples/${PROJECT_VAGRANT_CONFIGURATION_FILE}"; do \
		if echo "$${fil}" | grep --quiet "-"; then \
			echo "make: $${fil} should not contain a dash in the filename"; \
		fi \
	done
>	${ANSIBLE_LINT}
>	${NPX} ${MARKDOWNLINT_CLI2} \
		'**/*.md' \
		'!./node_modules' \
		'!./vendor' \
		'!./ansible'

.PHONY: ${FORMAT}
${FORMAT}:
>	${NPX} ${PRETTIER} --write './docs/*.md'

.PHONY: ${DEVELOPMENT_SHELL}
${DEVELOPMENT_SHELL}:
>	${BASH} -i

.PHONY: ${ANSIBLE_SECRETS}
${ANSIBLE_SECRETS}:
>	@${NPX} ${BW} login --check > /dev/null 2>&1 \
		|| { \
				echo "make: login to bitwarden and export BW_SESSION before running this target"; \
				exit 1; \
			}
>	@${NPX} ${BW} unlock --check > /dev/null 2>&1 \
		|| { \
				echo "make: unlock bitwarden vault and export BW_SESSION before running this target"; \
				exit 1; \
			}
ifeq (${ANSIBLE_SECRETS_ACTION},${PUT})
>	${ANSIBLE_VAULT} encrypt "${ANSIBLE_SECRETS_FILE_PATH}"
>	${NPX} ${BW} delete attachment \
		"$$(${NPX} ${BW} list items \
			| ${YQ} '.[] | select(.attachments?).attachments[] | select(.fileName=="${ANSIBLE_SECRETS_FILE}").id' \
		)" \
		--itemid "${BITWARDEN_ANSIBLE_SECRETS_ITEMID}"

>	${NPX} ${BW} create attachment \
		--file "${ANSIBLE_SECRETS_FILE_PATH}" \
		--itemid "${BITWARDEN_ANSIBLE_SECRETS_ITEMID}"
else
>	${NPX} ${BW} get attachment \
		"${ANSIBLE_SECRETS_FILE}" \
		--itemid "${BITWARDEN_ANSIBLE_SECRETS_ITEMID}" \
		--output "${ANSIBLE_SECRETS_DIR_PATH}/"

>	${ANSIBLE_VAULT} decrypt "${ANSIBLE_SECRETS_FILE_PATH}"

>	@for rsa_key in ${BITWARDEN_RSA_KEYS}; do \
		echo ${NPX} ${BW} get attachment \
			"$${rsa_key}" \
			--itemid \"${BITWARDEN_RSA_KEYS_ITEMID}\" \
			--output \"${BITWARDEN_RSA_KEYS_DIR_PATH}/$${rsa_key}\"; \
		\
		${NPX} ${BW} get attachment \
			"$${rsa_key}" \
			--itemid "${BITWARDEN_RSA_KEYS_ITEMID}" \
			--output "${BITWARDEN_RSA_KEYS_DIR_PATH}/$${rsa_key}"; \
	done

>	@for tls_cert in ${BITWARDEN_TLS_CERTS}; do \
		echo ${NPX} ${BW} get attachment \
			"$${tls_cert}" \
			--itemid \"${BITWARDEN_TLS_CERTS_ITEMID}\" \
			--output \"${BITWARDEN_TLS_CERTS_DIR_PATH}/$${tls_cert}\"; \
		\
		${NPX} ${BW} get attachment \
			"$${tls_cert}" \
			--itemid "${BITWARDEN_TLS_CERTS_ITEMID}" \
			--output "${BITWARDEN_TLS_CERTS_DIR_PATH}/$${tls_cert}"; \
	done

>	@for wireguard_key in ${BITWARDEN_WIREGUARD_KEYS}; do \
		echo ${NPX} ${BW} get attachment \
			"$${wireguard_key}" \
			--itemid \"${BITWARDEN_WIREGUARD_KEYS_ITEMID}\" \
			--output \"${BITWARDEN_WIREGUARD_KEYS_DIR_PATH}/$${wireguard_key}\"; \
		\
		${NPX} ${BW} get attachment \
			"$${wireguard_key}" \
			--itemid "${BITWARDEN_WIREGUARD_KEYS_ITEMID}" \
			--output "${BITWARDEN_WIREGUARD_KEYS_DIR_PATH}/$${wireguard_key}"; \
	done
endif

.PHONY: ${K8S_NODE_IMAGES}
${K8S_NODE_IMAGES}:
>	@[ -n "${PREFERRED_NAMESERVER}" ] \
		|| { echo "make: PREFERRED_NAMESERVER was not passed into make"; exit 1; }

>	@[ -n "${ANSIBLE_USER_PASSWORD}" ] \
		|| { echo "make: ANSIBLE_USER_PASSWORD was not passed into make"; exit 1; }

>	@[ -n "${ENCRYPTED_ANSIBLE_USER_PASSWORD}" ] \
		|| { echo "make: ENCRYPTED_ANSIBLE_USER_PASSWORD was not passed into make"; exit 1; }

	# Password and password hashes could contain the '$' char which make will try
	# to perform variable expansion on, hence the value func is used to prevent said
	# expansion.
>	ANSIBLE_VERBOSITY=0 ${ANSIBLE} \
		--module-name "ansible.builtin.template" \
		--args 'src=./preseed.cfg.j2 dest=./playbooks/files/packer/preseed.cfg mode="644"' \
		--extra-vars '{"encrypted_password":"$(value ENCRYPTED_ANSIBLE_USER_PASSWORD)","encryption_passphrase":"$(value ENCRYPTION_PASSPHRASE)","encrypt_disks":false,"for_vms":true}' \
		"localhost"

>	${PACKER} build \
		-var ansible_user_password='$(value ANSIBLE_USER_PASSWORD)' \
		-var preferred_nameserver="${PREFERRED_NAMESERVER}" \
		-var timezone_offset="$(shell date '+%-:z' | awk -F ":" '{ print $$1"h" }')" \
		"./k8s-nodes.pkr.hcl"

.PHONY: ${CONTAINERD_DEB}
${CONTAINERD_DEB}:
>	${CURL} \
		--location \
		--output "./playbooks/files/containerd_1.6.20~ds1-1+b1_amd64.deb" \
		"https://snapshot.debian.org/archive/debian/20230409T151531Z/pool/main/c/containerd/containerd_1.6.20~ds1-1%2Bb1_amd64.deb"

.PHONY: ${EXAMPLES_TEST}
${EXAMPLES_TEST}:
>	env --chdir "./extensions" ${MOLECULE} converge --scenario-name "examples_docker"
>	env --chdir "./extensions" ${MOLECULE} destroy --scenario-name "examples_docker"

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force ./logs/ansible.log.*
>	rm --force "./production"
>	rm \
		--recursive \
		--force \
		"./playbooks/files/packer/qemu-poseidon_k8s_controller" \
		"./playbooks/files/packer/qemu-poseidon_k8s_worker"

>	rm --force "./playbooks/files/containerd_1.6.20~ds1-1+b1_amd64.deb"
>	rm --force "./mitmproxy/bin/python"
ifeq (${VAGRANT_PROVIDER}, ${LIBVIRT})
	# There are times where vagrant may get into defunct state and will be unable to
	# remove a domain known to libvirt (through 'vagrant destroy'). Hence the calls
	# to virsh destroy and undefine.
>	-@for domain in ${LIBVIRT_DOMAINS}; do \
		echo ${VIRSH} destroy --domain "$${domain}"; \
		${VIRSH} destroy --domain "$${domain}"; \
	done

>	-@for domain in ${LIBVIRT_DOMAINS}; do \
		echo ${VIRSH} undefine --remove-all-storage --domain "$${domain}"; \
		${VIRSH} undefine --remove-all-storage --domain "$${domain}"; \
	done
>	${VAGRANT} destroy --force

	# done in recommendation by vagrant when a domain fails to connect via ssh
>	rm --recursive --force "./.vagrant"
>	${PKILL} ssh-agent
else
>	@echo make: unknown VAGRANT_PROVIDER \'${VAGRANT_PROVIDER}\' passed in
endif
