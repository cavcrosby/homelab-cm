include base.mk

# recursively expanded variables
ANSIBLE_SECRETS_DIR_PATH = ./playbooks/vars
ANSIBLE_SECRETS_FILE = ansible_secrets.yml
ANSIBLE_SECRETS_FILE_PATH = ${ANSIBLE_SECRETS_DIR_PATH}/${ANSIBLE_SECRETS_FILE}
BITWARDEN_ANSIBLE_SECRETS_ITEMID = a50012a3-3685-454c-b480-adf300ec834c
BITWARDEN_CLI_VERSION = 1.19.1
BITWARDEN_CLI_DIR_PATH = $(shell echo "$${HOME}/.local/bin")
BITWARDEN_CLI_PATH = ${BITWARDEN_CLI_DIR_PATH}/${BW}
BITWARDEN_DOWNLOAD_PATH = /tmp/bw-${BITWARDEN_CLI_VERSION}
VAGRANT_LIBVIRT_PLUGIN_VERSION = 0.7.0
VAGRANT_LIBVIRT_PLUGIN_PREFIX = vagrant-libvirt-${VAGRANT_LIBVIRT_PLUGIN_VERSION}
VAGRANT_LIBVIRT_PLUGIN_DOWNLOAD_DIR_PATH = /tmp
VAGRANT_LIBVIRT_PLUGIN_DOWNLOAD_PATH = ${VAGRANT_LIBVIRT_PLUGIN_DOWNLOAD_DIR_PATH}/${VAGRANT_LIBVIRT_PLUGIN_PREFIX}.tar.gz
export PROJECT_VAGRANT_CONFIGURATION_FILE = vagrant_ansible_vars.json
export ANSIBLE_CONFIG = ./ansible.cfg

# targets
PRODUCTION = production
STAGING = staging
ANSIBLE_SECRETS = ansible-secrets
DEVELOPMENT_SHELL = development-shell
DIAGRAM = diagram

# ansible-secrets actions
PUT = put

# libvirt provider configurations
LIBVIRT = libvirt
export LIBVIRT_PREFIX = $(shell basename ${CURDIR})_

# to be (or can be) passed in at make runtime
LOG =
LOG_PATH = ./ansible.log
VAGRANT_PROVIDER = ${LIBVIRT}
export ANSIBLE_TAGS = all

# ANSIBLE_VERBOSITY currently exists as an accounted env var for ansible, for
# reference:
# https://docs.ansible.com/ansible/latest/reference_appendices/config.html#envvar-ANSIBLE_VERBOSITY
export ANSIBLE_VERBOSITY_OPT = -v

ifeq (${ANSIBLE_SECRETS_ACTION},${PUT})
	SKIP_BITWARDEN_GET_SSH_KEYS = true
	SKIP_BITWARDEN_GET_TLS_CERTS = true
else
endif

# include other generic makefiles
include python.mk
# overrides defaults set by included makefiles
VIRTUALENV_PYTHON_VERSION = 3.9.5

include bitwarden.mk
BITWARDEN_SSH_KEYS_DIR_PATH = ./playbooks/ssh_keys
BITWARDEN_SSH_KEYS_ITEMID = 9493f9e9-82e0-458f-b609-ae20004f8227
BITWARDEN_SSH_KEYS = \
	LightsailDefaultKey-us-east-1.pem\
	id_rsa_irc.pub\
	id_rsa_github_1

BITWARDEN_TLS_CERTS_DIR_PATH = ./playbooks/certs
BITWARDEN_TLS_CERTS_ITEMID = 0857a42d-0d60-4ecc-8c43-ae200066a2b3
BITWARDEN_TLS_CERTS = \
	libera.pem\
	k8s_staging_ca.crt\
	k8s_ca.crt

include ansible.mk

# executables
BASH = bash
VIRSH = virsh
VAGRANT = vagrant
LXC = lxc
GEM = gem
PERL = perl
PKILL = pkill
JQ = jq
SUDO = sudo
BW = bw

# simply expanded variables
ifneq ($(findstring ${CONTROLLER_NODE},${TRUTHY_VALUES}),)
	executables := \
		${JQ}\
		${python_executables}
else
	executables := \
		${VIRSH}\
		${VAGRANT}\
		${PKILL}\
		${JQ}\
		${PERL}\
		${LXC}\
		${GEM}\
		${SUDO}\
		${BASH}\
		${python_executables}
endif
_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))

# provider VM identifiers
VM_NAMES := $(shell ${JQ} < ${PROJECT_VAGRANT_CONFIGURATION_FILE} --raw-output '.ansible_host_vars | keys[]')
LIBVIRT_DOMAINS := $(shell for vm_name in ${VM_NAMES}; do echo ${LIBVIRT_PREFIX}$${vm_name}; done)

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
>	@echo '  ${ANSIBLE_LINT}         - lints the yaml configuration code and json'
>	@echo '                         configurations'
>	@echo '  ${ANSIBLE_SECRETS}      - manage secrets used by this project, by default'
>	@echo '                         secrets are pulled into the project'
>	@echo '  ${DEVELOPMENT_SHELL}    - runs a bash shell with make variables injected into'
>	@echo '                         it to work with the project'\''s Vagrantfile'
>	@echo '  ${DIAGRAM}              - generate a infrastructure diagram of my homelab'
>	@echo '  ${CLEAN}                - removes files generated from targets'
>	@echo 'Common make configurations (e.g. make [config]=1 [targets]):'
>	@echo '  ANSIBLE_TAGS             - set the tags denoting the tasks/roles/plays for'
>	@echo '                             Ansible to run (default: all)'
>	@echo '  VAGRANT_PROVIDER         - set the provider used for the virtual environment'
>	@echo '                             created by Vagrant (default: libvirt)'
>	@echo '  ANSIBLE_VERBOSITY_OPT    - set the verbosity level when running ansible commands,'
>	@echo '                             represented as the '-v' variant passed in (default: -v)'
>	@echo '  ANSIBLE_SECRETS_ACTION   - determines the action to take concerning project'
>	@echo '                             secrets (options: ${PUT})'
>	@echo '  CONTROLLER_NODE          - set this variable when running on a machine whose'
>	@echo '                             functionality is solely to act as a Ansible controller'
>	@echo '                             node (e.g. no hypervisor would be installed)'
>	@echo '  LOG                      - when set, stdout/stderr will be redirected to a log'
>	@echo '                             file (if the target supports it). LOG_PATH determines'
>	@echo '                             log path (default: ./ansible.log)'

.PHONY: ${SETUP}
${SETUP}: ${PYENV_POETRY_SETUP}
>	${ANSIBLE_GALAXY} collection install --requirements-file ./meta/requirements.yml
>	wget --quiet --output-document "${BITWARDEN_DOWNLOAD_PATH}" https://github.com/bitwarden/cli/releases/download/v${BITWARDEN_CLI_VERSION}/bw-linux-${BITWARDEN_CLI_VERSION}.zip
>	unzip -o -d "${BITWARDEN_CLI_DIR_PATH}" "${BITWARDEN_DOWNLOAD_PATH}"
>	chmod 755 "${BITWARDEN_CLI_PATH}"
ifndef CONTROLLER_NODE
>	${SUDO} ${GEM} install nokogiri

	# This was needed as it was observed that while one system already had the
	# vagrant-libvirt plugin installed (version 0.0.45). The version of the plugin
	# dates back to 2018, and has an issue where there is an additional underscore
	# appended to any user defined libvirt prefix for a domain. Any version to be
	# installed should be after the fix was pulled in or after commit c02905be.
>	wget --quiet --output-document "${VAGRANT_LIBVIRT_PLUGIN_DOWNLOAD_PATH}" https://github.com/vagrant-libvirt/vagrant-libvirt/archive/refs/tags/${VAGRANT_LIBVIRT_PLUGIN_VERSION}.tar.gz
>	tar zxvf "${VAGRANT_LIBVIRT_PLUGIN_DOWNLOAD_PATH}" --directory="${VAGRANT_LIBVIRT_PLUGIN_DOWNLOAD_DIR_PATH}"
>	cd "${VAGRANT_LIBVIRT_PLUGIN_DOWNLOAD_DIR_PATH}/${VAGRANT_LIBVIRT_PLUGIN_PREFIX}" \
>	&& ${GEM} build $$(find . -name '*.gemspec') \
>	&& ${VAGRANT} plugin install $$(find . -name '*.gem')
endif

.PHONY: ${PRODUCTION}
${PRODUCTION}:
>	${ANSIBLE_PLAYBOOK} ${ANSIBLE_VERBOSITY_OPT} --inventory production ./playbooks/site.yml --ask-become-pass

.PHONY: ${STAGING}
${STAGING}:
ifneq ($(findstring ${VMS_EXISTS},${TRUTHY_VALUES}),)
>	${VAGRANT} up --provision --no-destroy-on-error --provider "${VAGRANT_PROVIDER}" ${LOG}
else
>	${VAGRANT} up --no-destroy-on-error --provider "${VAGRANT_PROVIDER}" ${LOG}
endif

.PHONY: ${ANSIBLE_LINT}
${ANSIBLE_LINT}:
>	@for fil in ${src_yaml} ${PROJECT_VAGRANT_CONFIGURATION_FILE}; do \
>		if echo $${fil} | grep --quiet '-'; then \
>			echo "make: $${fil} should not contain a dash in the filename"; \
>		fi \
>	done
>	${ANSIBLE_LINT}

.PHONY: ${DEVELOPMENT_SHELL}
${DEVELOPMENT_SHELL}:
>	${BASH} -i

.PHONY: ${DIAGRAM}
${DIAGRAM}:
>	${PYTHON} hldiag.py

.PHONY: ${ANSIBLE_SECRETS}
${ANSIBLE_SECRETS}: ${BITWARDEN_SESSION_CHECK} ${BITWARDEN_GET_SSH_KEYS} ${BITWARDEN_GET_TLS_CERTS}
ifeq (${ANSIBLE_SECRETS_ACTION},${PUT})
>	${ANSIBLE_VAULT} encrypt "${ANSIBLE_SECRETS_FILE_PATH}"
>	${BW} delete attachment \
		"$$(${BW} list items \
			| ${JQ} --raw-output '.[] | select(.attachments?).attachments[] | select(.fileName=="${ANSIBLE_SECRETS_FILE}").id' \
		)" \
		--itemid "${BITWARDEN_ANSIBLE_SECRETS_ITEMID}"
>	${BW} create attachment --file "${ANSIBLE_SECRETS_FILE_PATH}" --itemid "${BITWARDEN_ANSIBLE_SECRETS_ITEMID}"
else
>	${BW} get attachment "${ANSIBLE_SECRETS_FILE}" --itemid "${BITWARDEN_ANSIBLE_SECRETS_ITEMID}" --output "${ANSIBLE_SECRETS_DIR_PATH}/"
>	${ANSIBLE_VAULT} decrypt "${ANSIBLE_SECRETS_FILE_PATH}"
endif

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force *.log
>	rm --force homelab.png
ifeq ($(findstring ${CONTROLLER_NODE},${TRUTHY_VALUES}),)
	ifeq (${VAGRANT_PROVIDER}, ${LIBVIRT})
		# There are times where vagrant may get into defunct state and will be unable to
		# remove a domain known to libvirt (through 'vagrant destroy'). Hence the calls
		# to virsh destroy and undefine.
>		-@for domain in ${LIBVIRT_DOMAINS}; do \
>			echo ${VIRSH} destroy --domain $${domain}; \
>			${VIRSH} destroy --domain $${domain}; \
>		done

>		-@for domain in ${LIBVIRT_DOMAINS}; do \
>			echo ${VIRSH} undefine --domain $${domain}; \
>			${VIRSH} undefine --domain $${domain}; \
>		done
>		${VAGRANT} destroy --force

		# done in recommendation by vagrant when a domain fails to connect via ssh
>		rm --recursive --force ./.vagrant
>		${PKILL} ssh-agent
	else
>		@echo make: unknown VAGRANT_PROVIDER \'${VAGRANT_PROVIDER}\' passed in
	endif
endif
