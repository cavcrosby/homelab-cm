# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursive variables
SHELL = /usr/bin/sh
ANSIBLE_SECRETS_DIR_PATH = ./playbooks/vars
ANSIBLE_SSH_KEYS_DIR_PATH = ./playbooks/ssh_keys
ANSIBLE_TLS_CERTS_DIR_PATH = ./playbooks/certs
ANSIBLE_SECRETS_FILE = ansible_secrets.yaml
ANSIBLE_SECRETS_FILE_PATH = ${ANSIBLE_SECRETS_DIR_PATH}/${ANSIBLE_SECRETS_FILE}
BITWARDEN_ANSIBLE_SECRETS_ITEMID = a50012a3-3685-454c-b480-adf300ec834c
BITWARDEN_CLI_VERSION = 1.19.1
BITWARDEN_CLI_DIR_PATH = $(shell echo "$${HOME}/.local/bin")
BITWARDEN_CLI_PATH = ${BITWARDEN_CLI_DIR_PATH}/${BW}
BITWARDEN_DOWNLOAD_PATH = /tmp/bw-${BITWARDEN_CLI_VERSION}
VIRTUALENV_PYTHON_VERSION = 3.9.5
VAGRANT_LIBVIRT_PLUGIN_VERSION = 0.7.0
VAGRANT_LIBVIRT_PLUGIN_PREFIX = vagrant-libvirt-${VAGRANT_LIBVIRT_PLUGIN_VERSION}
VAGRANT_LIBVIRT_PLUGIN_DOWNLOAD_DIR_PATH = /tmp
VAGRANT_LIBVIRT_PLUGIN_DOWNLOAD_PATH = ${VAGRANT_LIBVIRT_PLUGIN_DOWNLOAD_DIR_PATH}/${VAGRANT_LIBVIRT_PLUGIN_PREFIX}.tar.gz
export PROJECT_VAGRANT_CONFIGURATION_FILE = vagrant_ansible_vars.json
export ANSIBLE_CONFIG = ./ansible.cfg

BITWARDEN_SSH_KEYS_ITEMID = 9493f9e9-82e0-458f-b609-ae20004f8227
SSH_KEYS = \
	LightsailDefaultKey-us-east-1.pem\
	id_rsa_irc.pub\
	id_rsa_github_1

BITWARDEN_TLS_CERTS_ITEMID = 0857a42d-0d60-4ecc-8c43-ae200066a2b3
TLS_CERTS = \
	libera.pem

# targets
HELP = help
SETUP = setup
PYTHON_VIRTUALENV_SETUP = python-virtualenv-setup
ANSIPLAY = ansiplay
ANSIPLAY_TEST = ansiplay-test
ANSISCRTS = ansiscrts
LINT = lint
DEV_SHELL = dev-shell
CLEAN = clean

# ansiscrts actions
PUT = put

# libvirt provider configurations
LIBVIRT = libvirt
export LIBVIRT_PREFIX = $(shell basename ${CURDIR})_

# executables
ANSIBLE_GALAXY = ansible-galaxy
ANSIBLE_LINT = ansible-lint
ANSIBLE_PLAYBOOK = ansible-playbook
ANSIBLE_VAULT = ansible-vault
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
PYENV = pyenv
PYTHON = python
PIP = pip
POETRY = poetry
ifdef CONTROLLER_NODE
	executables = \
		${ANSIBLE_PLAYBOOK}\
		${ANSIBLE_GALAXY}\
		${ANSIBLE_VAULT}\
		${JQ}\
		${PYENV}\
		${PYTHON}\
		${PIP}
else
	executables = \
		${VIRSH}\
		${VAGRANT}\
		${PKILL}\
		${JQ}\
		${PERL}\
		${LXC}\
		${ANSIBLE_PLAYBOOK}\
		${ANSIBLE_GALAXY}\
		${ANSIBLE_LINT}\
		${ANSIBLE_VAULT}\
		${GEM}\
		${SUDO}\
		${BASH}\
		${PYENV}\
		${PYTHON}\
		${PIP}
endif

# to be (or can be) passed in at make runtime
LOG =
LOG_PATH = ./ansible.log
VAGRANT_PROVIDER = ${LIBVIRT}
export ANSIBLE_TAGS = all

# ANSIBLE_VERBOSITY currently exists as an accounted env var for ansible, for
# reference:
# https://docs.ansible.com/ansible/latest/reference_appendices/config.html#envvar-ANSIBLE_VERBOSITY
export ANSIBLE_VERBOSITY_OPT = -v

# simply expanded variables
_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))
python_virtualenv_name := $(shell basename ${CURDIR})
src_yaml := $(shell find . \( -type f \) \
	-and \( -name '*.yaml' \) \
)

# provider VM identifiers
VM_NAMES := $(shell ${JQ} < ${PROJECT_VAGRANT_CONFIGURATION_FILE} --raw-output '.ansible_host_vars | keys[]')
LIBVIRT_DOMAINS := $(shell for vm_name in ${VM_NAMES}; do echo ${LIBVIRT_PREFIX}$${vm_name}; done)
CTRSERVERS := $(shell ${JQ} < ${PROJECT_VAGRANT_CONFIGURATION_FILE} --raw-output '.ansible_host_vars | keys[] | match("ctrserver[0-9]+"; "g").string')

ifeq (${VAGRANT_PROVIDER},${LIBVIRT})
	ifneq ($(shell for domain in ${LIBVIRT_DOMAINS}; do ${VIRSH} list --all --name | ${PERL} -pi -e 'chomp if eof' 2> /dev/null | grep "$${domain}"; done),)
		VMS_EXISTS := 1
	endif
# else (${VAGRANT_PROVIDER},${VBOX})
# 	ifneq ($(code that determines if virtualbox VMs exist),)
# 		VMS_EXISTS=1
# 	endif
endif

ifdef LOG
	override LOG := > ${LOG_PATH} 2>&1
endif

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Common make targets:'
>	@echo '  ${SETUP}          - installs the distro-independent dependencies for this'
>	@echo '                   project'
>	@echo '  ${ANSIPLAY}       - runs the main playbook for my homelab'
>	@echo '  ${ANSIPLAY_TEST}  - runs the main playbook for my homelab, but in a'
>	@echo '                   virtual environment setup by Vagrant'
>	@echo '  ${LINT}       	 - lints the yaml configuration code and json'
>	@echo '                   configurations'
>	@echo '  ${ANSISCRTS}      - manage secrets used by this project, by default'
>	@echo '                   secrets are pulled into the project'
>	@echo '  ${DEV_SHELL}      - runs a bash shell with make variables injected into'
>	@echo '                   it to work with the project'\''s Vagrantfile'
>	@echo '  ${CLEAN}          - removes files generated from targets'
>	@echo 'Common make configurations (e.g. make [config]=1 [targets]):'
>	@echo '  ANSIBLE_TAGS           - set the tags denoting the tasks/roles/plays for'
>	@echo '                           Ansible to run (default: all)'
>	@echo '  VAGRANT_PROVIDER       - set the provider used for the virtual environment'
>	@echo '                           created by Vagrant (default: libvirt)'
>	@echo '  ANSIBLE_VERBOSITY_OPT  - set the verbosity level when running ansible commands,'
>	@echo '                           represented as the '-v' variant passed in (default: -v)'
>	@echo '  ANSISCRTS_ACTION       - determines the action to take concerning project'
>	@echo '                           secrets (options: ${PUT})'
>	@echo '  CONTROLLER_NODE        - set this variable when running on a machine whose'
>	@echo '                           functionality is solely to act as a Ansible controller'
>	@echo '                           node (e.g. no hypervisor would be installed)'
>	@echo '  LOG                    - when set, stdout/stderr will be redirected to a log'
>	@echo '                           file (if the target supports it). LOG_PATH determines'
>	@echo '                           log path (default: ./ansible.log)'

.PHONY: ${PYTHON_VIRTUALENV_SETUP}
${PYTHON_VIRTUALENV_SETUP}:
>	@${PYENV} versions | grep --quiet '${VIRTUALENV_PYTHON_VERSION}$$' || { echo "make: python \"${VIRTUALENV_PYTHON_VERSION}\" is not installed by pyenv"; exit 1; }
>	${PYENV} virtualenv "${VIRTUALENV_PYTHON_VERSION}" "${python_virtualenv_name}"

	# mainly used to enter the virtualenv when in the repo
>	${PYENV} local "${python_virtualenv_name}"
>	export PYENV_VERSION="${python_virtualenv_name}"

	# to ensure the most current versions of dependencies can be installed
>	${PYTHON} -m ${PIP} install --upgrade ${PIP}
>	${PYTHON} -m ${PIP} install ${POETRY}==1.1.7

	# MONITOR(cavcrosby): temporary workaround due to poetry now breaking on some
	# package installs. For reference:
	# https://stackoverflow.com/questions/69836936/poetry-attributeerror-link-object-has-no-attribute-name#answer-69987715
>	${PYTHON} -m ${PIP} install poetry-core==1.0.4

	# --no-root because we only want to install dependencies. 'pyenv exec' is needed
	# as poetry is installed into a virtualenv bin dir that is not added to the
	# current shell PATH.
>	${PYENV} exec ${POETRY} install --no-root || { echo "${POETRY} failed to install project dependencies"; exit 1; }
>	unset PYENV_VERSION

.PHONY: ${SETUP}
${SETUP}: ${PYTHON_VIRTUALENV_SETUP}
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

.PHONY: ${ANSIPLAY}
${ANSIPLAY}:
>	${ANSIBLE_PLAYBOOK} ${ANSIBLE_VERBOSITY_OPT} --inventory production ./playbooks/site.yaml --ask-become-pass

.PHONY: ${ANSIPLAY_TEST}
${ANSIPLAY_TEST}:
ifdef VMS_EXISTS
>	${VAGRANT} up --provision --no-destroy-on-error --provider "${VAGRANT_PROVIDER}" ${LOG}
else
>	${VAGRANT} up --no-destroy-on-error --provider "${VAGRANT_PROVIDER}" ${LOG}
endif

.PHONY: ${LINT}
${LINT}:
>	@for fil in ${src_yaml} ${PROJECT_VAGRANT_CONFIGURATION_FILE}; do \
>		if echo $${fil} | grep --quiet '-'; then \
>			echo "make: $${fil} should not contain a dash in the filename"; \
>		fi \
>	done
>	${ANSIBLE_LINT}

.PHONY: ${DEV_SHELL}
${DEV_SHELL}:
>	${BASH} -i

.PHONY: ${ANSISCRTS}
${ANSISCRTS}:
>	@${BW} login --check > /dev/null 2>&1 || \
		{ \
			echo "make: login to bitwarden and export BW_SESSION before running this target"; \
			exit 1; \
		}
ifeq (${ANSISCRTS_ACTION}, ${PUT}) 
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

>	@for ssh_key in ${SSH_KEYS}; do \
>		echo ${BW} get attachment $${ssh_key} --itemid "${BITWARDEN_SSH_KEYS_ITEMID}" --output "${ANSIBLE_SSH_KEYS_DIR_PATH}/$${ssh_key}"; \
>		${BW} get attachment $${ssh_key} --itemid "${BITWARDEN_SSH_KEYS_ITEMID}" --output "${ANSIBLE_SSH_KEYS_DIR_PATH}/$${ssh_key}"; \
>	done

>	@for tls_cert in ${TLS_CERTS}; do \
>		echo ${BW} get attachment $${tls_cert} --itemid "${BITWARDEN_TLS_CERTS_ITEMID}" --output "${ANSIBLE_TLS_CERTS_DIR_PATH}/$${tls_cert}"; \
>		${BW} get attachment $${tls_cert} --itemid "${BITWARDEN_TLS_CERTS_ITEMID}" --output "${ANSIBLE_TLS_CERTS_DIR_PATH}/$${tls_cert}"; \
>	done
endif

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force *.log
ifndef CONTROLLER_NODE
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

		# Redeploying LXD on new VMs may cause cert issues when trying to reuse their
		# certs previously known the controller. The error would report something like,
		# "x509: certificate is valid for 127.0.0.1, ::1, not <ipv4_addr>".
>		-@for ctrserver in ${CTRSERVERS}; do \
>			echo ${LXC} remote remove "$$(${JQ} < ${PROJECT_VAGRANT_CONFIGURATION_FILE} \
				--arg CTRSERVER "$${ctrserver}" \
				--raw-output '.ansible_host_vars[$$CTRSERVER].vagrant_vm_ipv4_addr')"; \
>			${LXC} remote remove "$$(${JQ} < ${PROJECT_VAGRANT_CONFIGURATION_FILE} \
				--arg CTRSERVER "$${ctrserver}" \
				--raw-output '.ansible_host_vars[$$CTRSERVER].vagrant_vm_ipv4_addr')"; \
>		done

		# done in recommendation by vagrant when a domain fails to connect via ssh
>		rm --recursive --force ./.vagrant
>		${PKILL} ssh-agent
	else
>		@echo make: unknown VAGRANT_PROVIDER \'${VAGRANT_PROVIDER}\' passed in
	endif
endif
