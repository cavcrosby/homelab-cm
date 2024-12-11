"""Implementation of the task-values rule."""

from __future__ import annotations

import logging
from typing import TYPE_CHECKING

from ansiblelint.constants import (
    FILENAME_KEY,
    LINE_NUMBER_KEY,
    NESTED_TASK_KEYS,
    SKIPPED_RULES_KEY,
)
from ansiblelint.rules import AnsibleLintRule
from ansiblelint.text import has_jinja, is_fqcn
from jinja2 import Environment
from jinja2.nodes import Filter

from ansible.plugins.loader import (  # type: ignore # ansible.plugins.loader stubs don't exist
    filter_loader,
    init_plugin_loader,
)

if TYPE_CHECKING:
    from typing import Any

    from ansiblelint.errors import MatchError
    from ansiblelint.file_utils import Lintable
    from ansiblelint.utils import Task
    from jinja2.nodes import Node


logger = logging.getLogger(__name__)
init_plugin_loader()  # required before using loaders


class TaskValuesRule(AnsibleLintRule):
    """Rule for checking a task's values."""

    id = "task-values"
    description = "Task values must follow the set conventions."
    tags = ["homelab-cm"]
    _ids = {
        "task-values[shell-options]": "Start ansible.builtin.shell task with setting errexit and pipefail options (bash).",  # noqa E501
        "task-values[system-user-verbiage]": "Use 'system user' verbiage only for operating system system-level user accounts.",  # noqa E501
        "task-values[hardcode-users-name]": "Hardcode the operating system user's name in the task name.",  # noqa E501
        "task-values[pkg-names-order]": "List package names to task parameters in alphabetical order.",  # noqa E501
        "task-values[fqcn-in-filter]": "Use fully qualified collection names for ansible filters ({filter}).",  # noqa E501
        "task-values[yaml-sequences]": "Use yaml sequences for the notify, and when playbook keywords only when there is more than one element.",  # noqa E501
        "task-values[no-var-name]": "Do not include variables as part of a task's name",
    }

    def _get_leaf_nodes(self, node: list[Any] | dict[Any, Any]) -> list[Any]:
        """Get leaf/terminal nodes of a tree like data type (e.g. list, dict)."""

        def extract_leaf_nodes(node: Any) -> list[Any]:
            nodes: list[Any] = []
            # if a scalar like node; match parent func's node type hint
            if not isinstance(node, (list | dict)):
                return [node]
            for child in node.values() if isinstance(node, dict) else node:
                nodes += extract_leaf_nodes(child)

            return nodes

        return extract_leaf_nodes(node)

    def _get_filter_matcherrors(
        self, id_: str, task: Task, lintable: Lintable | None, strs: list[str]
    ) -> list[MatchError]:
        """Get match errors where Ansible filters do not use the FQCN format."""

        def extract_filters(node: Node) -> list[str]:
            return ([node.name] if isinstance(node, Filter) else []) + [
                filter_
                for child in node.iter_child_nodes()
                for filter_ in extract_filters(child)
            ]

        errors: list[MatchError] = []
        for str_ in strs:
            for filter_ in extract_filters(Environment().parse(str_)):
                if filter_loader.get(filter_) and not is_fqcn(filter_):
                    errors.append(
                        self.create_matcherror(
                            message=self._ids[id_].format(filter=filter_),
                            filename=lintable,
                            lineno=task[LINE_NUMBER_KEY],
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
            _id = f"{self.id}[shell-options]"
            errors.append(
                self.create_matcherror(
                    message=self._ids[_id],
                    filename=file,
                    lineno=task[LINE_NUMBER_KEY],
                    tag=_id,
                )
            )

        if task.action == "ansible.builtin.user" and task.name:
            if (
                "system user" in task.name
                and not task.args.get("system")
                or "system user" not in task.name
                and task.args.get("system")
            ):
                _id = f"{self.id}[system-user-verbiage]"
                errors.append(
                    self.create_matcherror(
                        message=self._ids[_id],
                        filename=file,
                        lineno=task[LINE_NUMBER_KEY],
                        tag=_id,
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
                _id = f"{self.id}[hardcode-users-name]"
                errors.append(
                    self.create_matcherror(
                        message=self._ids[_id],
                        filename=file,
                        lineno=task[LINE_NUMBER_KEY],
                        tag=_id,
                    )
                )

        pkg_list = task.args.get("name")
        if task.action == "ansible.builtin.apt" and pkg_list:
            sorted_pkg_list = sorted(pkg_list)
            if sorted_pkg_list != pkg_list:
                _id = f"{self.id}[pkg-names-order]"
                errors.append(
                    self.create_matcherror(
                        message=self._ids[_id],
                        filename=file,
                        lineno=task[LINE_NUMBER_KEY],
                        tag=_id,
                    )
                )

        errors.extend(
            self._get_filter_matcherrors(
                f"{self.id}[fqcn-in-filter]",
                task,
                file,
                [
                    node
                    for node in self._get_leaf_nodes(
                        {
                            key: value
                            # All task keys can only be accessed by items() via the
                            # normalized_task or raw_task properties.
                            for key, value in task.normalized_task.items()
                            if key
                            not in (
                                LINE_NUMBER_KEY,
                                SKIPPED_RULES_KEY,
                                FILENAME_KEY,
                                *NESTED_TASK_KEYS,
                            )
                        }
                    )
                    if isinstance(node, str)
                ],
            ),
        )

        if (
            isinstance(task.get("notify"), list)
            and len(task.get("notify", 0)) == 1
            or isinstance(task.get("when"), list)
            and len(task.get("when", 0)) == 1
        ):
            _id = f"{self.id}[yaml-sequences]"
            errors.append(
                self.create_matcherror(
                    message=self._ids[_id],
                    filename=file,
                    lineno=task[LINE_NUMBER_KEY],
                    tag=_id,
                )
            )

        if has_jinja(task.name):
            _id = f"{self.id}[no-var-name]"
            errors.append(
                self.create_matcherror(
                    message=self._ids[_id],
                    filename=file,
                    lineno=task[LINE_NUMBER_KEY],
                    tag=_id,
                )
            )

        return errors
