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
BITWARDEN_SSH_KEYS_DIR_PATH = ./playbooks/ssh_keys
BITWARDEN_SSH_KEYS_ITEMID = 9493f9e9-82e0-458f-b609-ae20004f8227
BITWARDEN_SSH_KEYS = \
	id_rsa_ron.pub\
	id_rsa_roxanne.pub

BITWARDEN_RSA_KEYS_DIR_PATH = ./playbooks/rsa_keys
BITWARDEN_RSA_KEYS_ITEMID = 0a2e75a3-7f1d-4720-ad05-aec2016c4ba9
BITWARDEN_RSA_KEYS = \
	poseidon_k8s_ca.key

BITWARDEN_TLS_CERTS_DIR_PATH = ./playbooks/certs
BITWARDEN_TLS_CERTS_ITEMID = 0857a42d-0d60-4ecc-8c43-ae200066a2b3
BITWARDEN_TLS_CERTS = \
	liberachat.pem\
	oftc.pem\
	poseidon_k8s_ca.crt

export PROJECT_VAGRANT_CONFIGURATION_FILE = vagrant_ansible_vars.json
export ANSIBLE_CONFIG = ./ansible.cfg

# targets
HELP = help
SETUP = setup
PRODUCTION = production
STAGING = staging
ANSIBLE_SECRETS = ansible-secrets
K8S_NODE_IMAGES = k8s-node-images
LINT = lint
DEVELOPMENT_SHELL = development-shell
CLEAN = clean

# ansible-secrets actions
PUT = put

# libvirt provider configurations
LIBVIRT = libvirt
export LIBVIRT_PREFIX = $(shell basename ${CURDIR})_

# to be (or can be) passed in at make runtime
LOG =
LOG_PATH = ./ansible.log
VAGRANT_PROVIDER = ${LIBVIRT}
export ANSIBLE_EXTRA_VARS =
export ANSIBLE_TAGS = all

# ANSIBLE_VERBOSITY currently exists as an accounted env var for ansible, for
# reference:
# https://docs.ansible.com/ansible/latest/reference_appendices/config.html#envvar-ANSIBLE_VERBOSITY
export ANSIBLE_VERBOSITY_OPT = -v

# executables
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
PERL = perl
PKILL = pkill
JQ = jq
BW = bw
PYTHON = python
PIP = pip
NPM = npm
NPX = npx

# simply expanded variables
executables := \
	${VIRSH}\
	${VAGRANT}\
	${PKILL}\
	${JQ}\
	${PERL}\
	${ANSIBLE_PLAYBOOK}\
	${ANSIBLE_GALAXY}\
	${ANSIBLE_LINT}\
	${ANSIBLE_VAULT}\
	${BUNDLE}\
	${GEM}\
	${BASH}\
	${PYTHON}\
	${NPM}\
	${PACKER}

_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))
src_yml := $(shell find . \( -type f \) \
	-and \( -name '*.yml' \) \
	-and ! \( -path './vendor/*' \) \
	-and ! \( -path './node_modules/*' \) \
)

# provider VM identifiers
VM_NAMES := $(shell ${JQ} < ${PROJECT_VAGRANT_CONFIGURATION_FILE} --raw-output '.ansible_host_vars | keys[]')
# include all VMs by default
VMS_INCLUDE := $(shell \
	${JQ} \
		--raw-output \
		< ${PROJECT_VAGRANT_CONFIGURATION_FILE} \
		'.vms_include[]? // (.ansible_host_vars | keys[])' \
)

LIBVIRT_DOMAINS := $(shell \
	for vm_name in ${VM_NAMES}; do \
		if echo "${VMS_INCLUDE}" | grep --quiet "$${vm_name}"; then \
			echo "${LIBVIRT_PREFIX}$${vm_name}"; \
		fi; \
	done \
)

ifeq (${VAGRANT_PROVIDER},${LIBVIRT})
	ifneq ($(shell for domain in ${LIBVIRT_DOMAINS}; do ${VIRSH} list --all --name | ${PERL} -pi -e 'chomp if eof' 2> /dev/null | grep "$${domain}"; done),)
		VMS_EXISTS := 1
	endif
# else (${VAGRANT_PROVIDER},${VBOX})
# 	ifneq ($(code that determines if virtualbox VMs exist),)
# 		VMS_EXISTS=1
# 	endif
endif

ifneq ($(findstring ${LOG},${TRUTHY_VALUES}),)
	override LOG := > ${LOG_PATH} 2>&1
endif

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Common make targets:'
>	@echo '  ${SETUP}                - installs the distro-independent dependencies for this'
>	@echo '                         project'
>	@echo '  ${PRODUCTION}           - runs the main playbook for my homelab'
>	@echo '  ${STAGING}              - runs the main playbook for my homelab, but in a'
>	@echo '                         virtual environment setup by Vagrant'
>	@echo '  ${LINT}                 - lints the yaml configuration code and json'
>	@echo '                         configurations'
>	@echo '  ${ANSIBLE_SECRETS}      - manage secrets used by this project, by default'
>	@echo '                         secrets are pulled into the project'
>	@echo '  ${DEVELOPMENT_SHELL}    - runs a bash shell with make variables injected into'
>	@echo '                         it to work with the project'\''s Vagrantfile'
>	@echo '  ${CLEAN}                - removes files generated from targets'
>	@echo 'Common make configurations (e.g. make [config]=1 [targets]):'
>	@echo '  ANSIBLE_TAGS             - set the tags denoting the tasks/roles/plays for'
>	@echo '                             Ansible to run (default: all)'
>	@echo '  VAGRANT_PROVIDER         - set the provider used for the virtual environment'
>	@echo '                             created by Vagrant (default: libvirt)'
>	@echo '  ANSIBLE_VERBOSITY_OPT    - set the verbosity level when running ansible commands,'
>	@echo '                             represented as the '-v' variant passed in (default: -v)'
>	@echo '  ANSIBLE_SECRETS_ACTION   - determines the action to take concerning project'
>	@echo '                             secrets (options: put)'
>	@echo '  ANSIBLE_EXTRA_VARS       - pass variables into the ansible-playbook runtime, see'
>	@echo '                             --extra-vars documentation on argument format'
>	@echo '  LOG                      - when set, stdout/stderr will be redirected to a log'
>	@echo '                             file (if the target supports it)'
>	@echo '  LOG_PATH                 - used with LOG, determines the log path (default: ./ansible.log)'

.PHONY: ${SETUP}
${SETUP}:
>	${BUNDLE} install
>	${VAGRANT} plugin install "$$(find ./vendor -name 'vagrant-libvirt-*.gem')"
>	${NPM} install
>	${ANSIBLE_GALAXY} collection install --requirements-file "./meta/requirements.yml"
>	${PYTHON} -m ${PIP} install --upgrade "${PIP}"
>	${PYTHON} -m ${PIP} install \
		--requirement "./requirements.txt" \
		--requirement "./dev-requirements.txt"

.PHONY: ${PRODUCTION}
${PRODUCTION}:
ifeq (${ANSIBLE_EXTRA_VARS},)
>	${ANSIBLE_PLAYBOOK} \
		${ANSIBLE_VERBOSITY_OPT} \
		--inventory "production" \
		"./playbooks/site.yml" \
		--ask-become-pass
else
>	${ANSIBLE_PLAYBOOK} \
		${ANSIBLE_VERBOSITY_OPT} \
		--ask-become-pass \
		--inventory "production" \
		--extra-vars ${ANSIBLE_EXTRA_VARS} \
		"./playbooks/site.yml"
endif

.PHONY: ${STAGING}
${STAGING}:
ifneq ($(findstring ${VMS_EXISTS},${TRUTHY_VALUES}),)
>	${VAGRANT} up \
		--provision \
		--no-destroy-on-error \
		--provider "${VAGRANT_PROVIDER}" \
		${LOG}
else
>	${VAGRANT} up --no-destroy-on-error --provider "${VAGRANT_PROVIDER}" ${LOG}
endif

.PHONY: ${LINT}
${LINT}:
>	@for fil in ${src_yml} ${PROJECT_VAGRANT_CONFIGURATION_FILE}; do \
		if echo "$${fil}" | grep --quiet '-'; then \
			echo "make: $${fil} should not contain a dash in the filename"; \
		fi \
	done
>	${ANSIBLE_LINT}

.PHONY: ${DEVELOPMENT_SHELL}
${DEVELOPMENT_SHELL}:
>	${BASH} -i

.PHONY: ${ANSIBLE_SECRETS}
${ANSIBLE_SECRETS}:
>	@${NPX} ${BW} login --check > /dev/null 2>&1 || \
		{ \
			echo "make: login to bitwarden and export BW_SESSION before running this target"; \
			exit 1; \
		}
>	@${NPX} ${BW} unlock --check > /dev/null 2>&1 || \
		{ \
			echo "make: unlock bitwarden vault and export BW_SESSION before running this target"; \
			exit 1; \
		}
ifeq (${ANSIBLE_SECRETS_ACTION},${PUT})
>	${ANSIBLE_VAULT} encrypt "${ANSIBLE_SECRETS_FILE_PATH}"
>	${NPX} ${BW} delete attachment \
		"$$(${NPX} ${BW} list items \
			| ${JQ} --raw-output '.[] | select(.attachments?).attachments[] | select(.fileName=="${ANSIBLE_SECRETS_FILE}").id' \
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

>	@for ssh_key in ${BITWARDEN_SSH_KEYS}; do \
		echo ${NPX} ${BW} get attachment \
			"$${ssh_key}" \
			--itemid \"${BITWARDEN_SSH_KEYS_ITEMID}\" \
			--output \"${BITWARDEN_SSH_KEYS_DIR_PATH}/$${ssh_key}\"; \
		\
		${NPX} ${BW} get attachment \
			"$${ssh_key}" \
			--itemid "${BITWARDEN_SSH_KEYS_ITEMID}" \
			--output "${BITWARDEN_SSH_KEYS_DIR_PATH}/$${ssh_key}"; \
	done

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
endif

.PHONY: ${K8S_NODE_IMAGES}
${K8S_NODE_IMAGES}:
>	@[ -n "${K8S_NODE_IMAGES_SSH_PASSWORD}" ] || \
		{ echo "make: K8S_NODE_IMAGES_SSH_PASSWORD was not passed into make"; exit 1; }

>	@[ -n "${K8S_NODE_IMAGES_ENCRYPTED_SSH_PASSWORD}" ] || \
		{ echo "make: K8S_NODE_IMAGES_ENCRYPTED_SSH_PASSWORD was not passed into make"; exit 1; }

	# Password and password hashes could contain the '$' char which make will try
	# to perform variable expansion on, hence the value func is used to prevent said
	# expansion.
>	${PACKER} build \
		-var ssh_password='$(value K8S_NODE_IMAGES_SSH_PASSWORD)' \
		-var encrypted_ssh_password='$(value K8S_NODE_IMAGES_ENCRYPTED_SSH_PASSWORD)' \
		"./k8s-nodes.pkr.hcl"

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force *.log
>	rm \
		--recursive \
		--force \
		"./packer/qemu-poseidon_k8s_controller" \
		"./packer/qemu-poseidon_k8s_worker"

ifeq (${VAGRANT_PROVIDER}, ${LIBVIRT})
	# There are times where vagrant may get into defunct state and will be unable to
	# remove a domain known to libvirt (through 'vagrant destroy'). Hence the calls
	# to virsh destroy and undefine.
>	-@for domain in ${LIBVIRT_DOMAINS}; do \
		echo ${VIRSH} destroy --domain "$${domain}"; \
		${VIRSH} destroy --domain "$${domain}"; \
	done

>	-@for domain in ${LIBVIRT_DOMAINS}; do \
		echo ${VIRSH} undefine --domain "$${domain}"; \
		${VIRSH} undefine --domain "$${domain}"; \
	done
>	${VAGRANT} destroy --force

	# done in recommendation by vagrant when a domain fails to connect via ssh
>	rm --recursive --force "./.vagrant"
>	${PKILL} ssh-agent
else
>	@echo make: unknown VAGRANT_PROVIDER \'${VAGRANT_PROVIDER}\' passed in
endif
