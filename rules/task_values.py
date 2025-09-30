"""Implementation of the task-values rule."""

from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING

from ansiblelint.constants import (
    LINE_NUMBER_KEY,
)
from ansiblelint.rules import AnsibleLintRule
from ansiblelint.text import has_jinja, is_fqcn
from ansiblelint.yaml_utils import nested_items_path
from jinja2 import Environment
from jinja2.nodes import Filter
from spellchecker import SpellChecker

from ansible.parsing.yaml.objects import (  # type: ignore # ansible.parsing.yaml.objects stubs don't exist
    AnsibleUnicode,
)
from ansible.plugins.loader import (  # type: ignore # ansible.plugins.loader stubs don't exist
    filter_loader,
    init_plugin_loader,
)

if TYPE_CHECKING:
    from typing import Any, TypeAlias

    from ansiblelint.errors import MatchError
    from ansiblelint.file_utils import Lintable
    from ansiblelint.utils import Task
    from jinja2.nodes import Node

    AnsibleUnicodeItems: TypeAlias = dict[int, AnsibleUnicode]

spell_checker = SpellChecker()
init_plugin_loader()  # required before using loaders
spell_checker.word_frequency.load_text_file(Path("./docs/dictionary.txt"))


class TaskValuesRule(AnsibleLintRule):
    """Rule for checking a task's values."""

    id = "task-values"
    description = "Task values must follow the set conventions."
    tags = ["homelab-cm"]
    _ids = {
        "task-values[shell-options]": "Start ansible.builtin.shell task with setting errexit and pipefail options (bash).",  # noqa E501
        "task-values[name-word-misspelled]": "Correct any misspelled words in task name ({word}).",  # noqa E501
        "task-values[system-user-verbiage]": "Use 'system user' verbiage only for operating system system-level user accounts.",  # noqa E501
        "task-values[hardcode-users-name]": "Hardcode the operating system user's name in the task name.",  # noqa E501
        "task-values[append-distro]": "Append distribution specificness to tasks where appropriate.",  # noqa E501
        "task-values[pkg-names-order]": "List package names to task parameters in alphabetical order.",  # noqa E501
        "task-values[fqcn-in-filter]": "Use fully qualified collection names for ansible filters ({filter}).",  # noqa E501
        "task-values[yaml-sequences]": "Use yaml sequences for the notify, and when playbook keywords only when there is more than one element.",  # noqa E501
        "task-values[no-var-name]": "Do not include variables as part of a task's name",
        "task-values[append-systemd-unit]": "Append the systemd.unit(5) type suffix to the systemd unit.",  # noqa E501
    }

    def _get_leaf_items(self, node: list[Any] | dict[Any, Any]) -> AnsibleUnicodeItems:
        """Get leaf/terminal AnsibleUnicode items of a tree and their indexes."""
        items: AnsibleUnicodeItems = {}
        previous_item: tuple[Any, Any, list[str | int]] | tuple[()] = ()
        for key, value, parent in nested_items_path(node):
            if (
                previous_item
                and (
                    not parent
                    # first item in list
                    or parent == previous_item[0]
                    # 1+n item in list (n > 0)
                    or parent == previous_item[2]
                )
                and isinstance(previous_item[1], AnsibleUnicode)
            ):
                items[previous_item[1].ansible_pos[1]] = previous_item[1]
            previous_item = (key, value, parent)

        # add the last previous item
        if previous_item and isinstance(previous_item[1], AnsibleUnicode):
            items[previous_item[1].ansible_pos[1]] = previous_item[1]

        return items

    def _get_filter_matcherrors(
        self, id_: str, lintable: Lintable | None, items: AnsibleUnicodeItems
    ) -> list[MatchError]:
        """Get match errors where Ansible filters do not use the FQCN format."""

        def extract_filters(node: Node) -> list[str]:
            return ([node.name] if isinstance(node, Filter) else []) + [
                filter_
                for child in node.iter_child_nodes()
                for filter_ in extract_filters(child)
            ]

        errors: list[MatchError] = []
        for item in items:
            for filter_ in extract_filters(Environment().parse(items[item])):
                if filter_loader.get(filter_) and not is_fqcn(filter_):
                    errors.append(
                        self.create_matcherror(
                            message=self._ids[id_].format(filter=filter_),
                            filename=lintable,
                            lineno=item,
                            tag=id_,
                        ),
                    )

        return errors

    def matchtask(
        self,
        task: Task,
        file: Lintable | None = None,
    ) -> bool | str | MatchError | list[MatchError]:
        """Task matching method."""
        errors: list[MatchError] = []
        if task.action == "ansible.builtin.shell" and not task.args["cmd"].startswith(
            "set -eo pipefail"
        ):
            id_ = f"{self.id}[shell-options]"
            errors.append(
                self.create_matcherror(
                    message=self._ids[id_],
                    filename=file,
                    lineno=task[LINE_NUMBER_KEY],
                    tag=id_,
                )
            )

        if task.name:
            id_ = f"{self.id}[name-word-misspelled]"
            for unknown_word in spell_checker.unknown(
                [word for word in spell_checker.split_words(task.name)]
            ):
                errors.append(
                    self.create_matcherror(
                        message=self._ids[id_].format(word=unknown_word),
                        filename=file,
                        lineno=task[LINE_NUMBER_KEY],
                        tag=id_,
                    )
                )

        if task.action == "ansible.builtin.user" and task.name:
            if (
                "system user" in task.name
                and not task.args.get("system")
                or "system user" not in task.name
                and task.args.get("system")
            ):
                id_ = f"{self.id}[system-user-verbiage]"
                errors.append(
                    self.create_matcherror(
                        message=self._ids[id_],
                        filename=file,
                        lineno=task[LINE_NUMBER_KEY],
                        tag=id_,
                    )
                )

            if (
                # Use empty str default to prevent missing name arg from causing an
                # exception.
                (
                    task.args.get("name", "") not in task.name
                    or "ansible_user" in task.args.get("name", "")
                )
                and "ansible_user" not in task.name
            ):
                id_ = f"{self.id}[hardcode-users-name]"
                errors.append(
                    self.create_matcherror(
                        message=self._ids[id_],
                        filename=file,
                        lineno=task[LINE_NUMBER_KEY],
                        tag=id_,
                    )
                )

        if (
            (
                task.action == "ansible.builtin.apt"
                or task.action == "ansible.builtin.apt_repository"
                or task.action == "ansible.builtin.dpkg_selections"
                or task.action == "community.general.locale_gen"
            )
            and task.name
            and "(debian-like)" not in task.name
        ):
            id_ = f"{self.id}[append-distro]"
            errors.append(
                self.create_matcherror(
                    message=self._ids[id_],
                    filename=file,
                    lineno=task[LINE_NUMBER_KEY],
                    tag=id_,
                )
            )

        pkg_list = task.args.get("name")
        if task.action == "ansible.builtin.apt" and pkg_list:
            sorted_pkg_list = sorted(pkg_list)
            if sorted_pkg_list != pkg_list:
                id_ = f"{self.id}[pkg-names-order]"
                errors.append(
                    self.create_matcherror(
                        message=self._ids[id_],
                        filename=file,
                        lineno=task[LINE_NUMBER_KEY],
                        tag=id_,
                    )
                )

        errors.extend(
            self._get_filter_matcherrors(
                f"{self.id}[fqcn-in-filter]",
                file,
                {key: value for key, value in self._get_leaf_items(task).items()},
            ),
        )

        if (
            isinstance(task.get("notify"), list)
            and len(task.get("notify", 0)) == 1
            or isinstance(task.get("when"), list)
            and len(task.get("when", 0)) == 1
        ):
            id_ = f"{self.id}[yaml-sequences]"
            errors.append(
                self.create_matcherror(
                    message=self._ids[id_],
                    filename=file,
                    lineno=task[LINE_NUMBER_KEY],
                    tag=id_,
                )
            )

        if has_jinja(task.name):
            id_ = f"{self.id}[no-var-name]"
            errors.append(
                self.create_matcherror(
                    message=self._ids[id_],
                    filename=file,
                    lineno=task[LINE_NUMBER_KEY],
                    tag=id_,
                )
            )

        unit_name = task.args.get("name")
        if (
            task.action == "ansible.builtin.systemd_service"
            and unit_name
            and not any(
                # unit suffixes from systemd.unit(5)
                suffix in unit_name
                for suffix in (
                    ".service",
                    ".socket",
                    ".device",
                    ".mount",
                    ".automount",
                    ".swap",
                    ".target",
                    ".path",
                    ".timer",
                    ".slice",
                    ".scope",
                )
            )
        ):
            id_ = f"{self.id}[append-systemd-unit]"
            errors.append(
                self.create_matcherror(
                    message=self._ids[id_],
                    filename=file,
                    lineno=task[LINE_NUMBER_KEY],
                    tag=id_,
                )
            )

        return errors

    def matchyaml(self, file: Lintable) -> list[MatchError]:
        """YAML matching method."""
        errors: list[MatchError] = []
        if str(file.kind) == "vars":
            errors.extend(
                self._get_filter_matcherrors(
                    f"{self.id}[fqcn-in-filter]",
                    file,
                    self._get_leaf_items(file.data),
                ),
            )
        return errors
