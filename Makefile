# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursive variables
SHELL = /usr/bin/sh
export PROJECT_VAGRANT_CONFIGURATION_FILE = vagrant-ansible-vars.json
export ANSIBLE_CONFIG = ./ansible.cfg

# targets
HELP = help
SETUP = setup
ANSIPLAY = ansiplay
ANSIPLAY_TEST = ansiplay-test
ANSILINT = ansilint
DEV_SHELL = dev-shell
CLEAN = clean

# libvirt provider configurations
LIBVIRT = libvirt
export LIBVIRT_PREFIX = $(shell basename ${CURDIR})_

# executables
ANSIBLE_GALAXY = ansible-galaxy
ANSIBLE_LINT = ansible-lint
ANSIBLE_PLAYBOOK = ansible-playbook
BASH = bash
VIRSH = virsh
VAGRANT = vagrant
LXC = lxc
GEM = gem
PERL = perl
PKILL = pkill
JQ = jq
SUDO = sudo
executables = \
	${VIRSH}\
	${VAGRANT}\
	${PKILL}\
	${JQ}\
	${PERL}\
	${LXC}\
	${ANSIBLE_PLAYBOOK}\
	${ANSIBLE_GALAXY}\
	${GEM}\
	${SUDO}\
	${BASH}

# to be (or can be) passed in at make runtime
VAGRANT_PROVIDER = ${LIBVIRT}
# ANSIBLE_VERBOSITY currently exists as an accounted env var for ansible, for
# reference:
# https://docs.ansible.com/ansible/latest/reference_appendices/config.html#envvar-ANSIBLE_VERBOSITY
export ANSIBLE_VERBOSITY_OPT = -v

# simply expanded variables
_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))
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

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Common make targets:'
>	@echo '  ${SETUP}          - installs the distro-independent dependencies for this'
>	@echo '                   project'
>	@echo '  ${ANSIPLAY}       - runs the main playbook for my homelab'
>	@echo '  ${ANSIPLAY_TEST}  - runs the main playbook for my homelab, but in a'
>	@echo '                   virtual environment setup by Vagrant'
>	@echo '  ${ANSILINT}       - runs the yaml configuration code through a'
>	@echo '                   ansible linter'
>	@echo '  ${DEV_SHELL}      - runs a bash shell with make variables injected into'
>	@echo '                   it to work with the project'\''s Vagrantfile'
>	@echo '  ${CLEAN}          - removes files generated from targets'
>	@echo 'Common make configurations (e.g. make [config]=1 [targets]):'
>	@echo '  VAGRANT_PROVIDER       - set the provider used for the virtual environment'
>	@echo '                           created by Vagrant (default: libvirt)'
>	@echo '  ANSIBLE_VERBOSITY_OPT  - set the verbosity level when running ansible commands,'
>	@echo '                           represented as the '-v' variant passed in (default: -v)'

.PHONY: ${SETUP}
${SETUP}:
>	${ANSIBLE_GALAXY} collection install --requirements-file requirements.yaml
>	${SUDO} ${GEM} install nokogiri

.PHONY: ${ANSIPLAY}
${ANSIPLAY}:
>	${ANSIBLE_PLAYBOOK} ${ANSIBLE_VERBOSITY_OPT} --inventory production site.yaml --ask-become-pass

.PHONY: ${ANSIPLAY_TEST}
${ANSIPLAY_TEST}:
ifdef VMS_EXISTS
>	${VAGRANT} up --provision --no-destroy-on-error --provider "${VAGRANT_PROVIDER}"
else
>	${VAGRANT} up --no-destroy-on-error --provider "${VAGRANT_PROVIDER}"
endif

.PHONY: ${ANSILINT}
${ANSILINT}:
>	${ANSIBLE_LINT} ${src_yaml}

.PHONY: ${DEV_SHELL}
${DEV_SHELL}:
>	${BASH} -i

.PHONY: ${CLEAN}
${CLEAN}:
ifeq (${VAGRANT_PROVIDER}, ${LIBVIRT})
	# There are times where vagrant may get into defunct state and will be unable to
	# remove a domain known to libvirt (through 'vagrant destroy'). Hence the calls
	# to virsh destroy and undefine.
>	-@for domain in ${LIBVIRT_DOMAINS}; do \
>		echo ${VIRSH} destroy --domain $${domain}; \
>		${VIRSH} destroy --domain $${domain}; \
>	done

>	-@for domain in ${LIBVIRT_DOMAINS}; do \
>		echo ${VIRSH} undefine --domain $${domain}; \
>		${VIRSH} undefine --domain $${domain}; \
>	done
>	${VAGRANT} destroy --force

	# Redeploying LXD on new VMs may cause cert issues when trying to reuse their
	# certs previously known the controller. The error would report something like,
	# "x509: certificate is valid for 127.0.0.1, ::1, not <ipv4_addr>".
>	-@for ctrserver in ${CTRSERVERS}; do \
>		echo ${LXC} remote remove "$$(${JQ} < ${PROJECT_VAGRANT_CONFIGURATION_FILE} \
			--arg CTRSERVER "$${ctrserver}" \
			--raw-output '.ansible_host_vars[$$CTRSERVER].vagrant_vm_ipv4_addr')"; \
>		${LXC} remote remove "$$(${JQ} < ${PROJECT_VAGRANT_CONFIGURATION_FILE} \
			--arg CTRSERVER "$${ctrserver}" \
			--raw-output '.ansible_host_vars[$$CTRSERVER].vagrant_vm_ipv4_addr')"; \
>	done

	# done in recommendation by vagrant when a domain fails to connect via ssh
>	rm --recursive --force ./.vagrant
>	${PKILL} ssh-agent
else
>	@echo make: unknown VAGRANT_PROVIDER \'${VAGRANT_PROVIDER}\' passed in
endif
