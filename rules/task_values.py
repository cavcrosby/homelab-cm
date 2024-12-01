"""Implementation of the task-values rule."""

from __future__ import annotations

import logging
from typing import TYPE_CHECKING

from ansiblelint.constants import (
    LINE_NUMBER_KEY,
)
from ansiblelint.rules import AnsibleLintRule
from ansiblelint.text import has_jinja

if TYPE_CHECKING:
    from ansiblelint.errors import MatchError
    from ansiblelint.file_utils import Lintable
    from ansiblelint.utils import Task


logger = logging.getLogger(__name__)


class TaskValuesRule(AnsibleLintRule):
    """Rule for checking a task's values."""

    id = "task-values"
    description = "Task values must follow the set conventions."
    tags = ["homelab-cm"]
    _ids = {
        "task-values[shell-options]": "Start ansible.builtin.shell task with setting errexit and pipefail options (bash).",
        "task-values[system-user-verbiage]": "Use 'system user' verbiage only for operating system system-level user accounts.",
        "task-values[hardcode-users-name]": "Hardcode the operating system user's name in the task name.",
        "task-values[pkg-names-order]": "List package names to task parameters in alphabetical order.",
        "task-values[yaml-sequences]": "Use yaml sequences for the notify, and when playbook keywords only when there is more than one element.",
        "task-values[no-var-name]": "Do not include variables as part of a task's name",
    }

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
                and not task.args.get("system", False)
                or "system user" not in task.name
                and task.args.get("system", False)
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
                task.args.get("name", "") not in task.name
                and "ansible_user" in task.args.get("name", "")
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

        if (
            isinstance(task.raw_task.get("notify"), list)
            and len(task.raw_task.get("notify", 0)) == 1
            or isinstance(task.raw_task.get("when"), list)
            and len(task.raw_task.get("when", 0)) == 1
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
