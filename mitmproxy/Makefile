# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursively expanded variables
SHELL = /usr/bin/sh

# targets
HELP = help
SETUP = setup

# executables
PYTHON = python
PIP = pip

# simply expanded variables
executables := \
	${PYTHON}

_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))

.PHONY: ${HELP}
${HELP}:
>	@echo 'Common make targets:'
>	@echo '  ${SETUP}                  - installs the distro-independent dependencies for this'
>	@echo '                           project'

.PHONY: ${SETUP}
${SETUP}:
>	${PYTHON} -m ${PIP} install --upgrade "${PIP}"
>	${PYTHON} -m ${PIP} install --requirement "./requirements-dev.txt"
