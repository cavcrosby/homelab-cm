"""Implementation of the task-module-args rule."""

from __future__ import annotations

from typing import TYPE_CHECKING

from ansiblelint.constants import (
    LINE_NUMBER_KEY,
)
from ansiblelint.rules import AnsibleLintRule

if TYPE_CHECKING:
    from ansiblelint.errors import MatchError
    from ansiblelint.file_utils import Lintable
    from ansiblelint.utils import Task


class TaskModuleAliasesRule(AnsibleLintRule):
    """Rule for checking a task module's arguments."""

    id = "task-module-args"
    description = "Task module's arguments must follow the set conventions."
    tags = ["homelab-cm"]
    _ids = {
        "task-module-args[checksum-param]": "Set the checksum parameter in ansible.builtin.get_url tasks.",  # noqa E501
    }

    def matchtask(
        self,
        task: Task,
        file: Lintable | None = None,
    ) -> bool | str | MatchError | list[MatchError]:
        """Task matching method."""
        errors: list[MatchError] = []
        if task.action == "ansible.builtin.get_url" and not task.args.get("checksum"):
            id_ = f"{self.id}[checksum-param]"
            errors.append(
                self.create_matcherror(
                    message=self._ids[id_],
                    filename=file,
                    lineno=task[LINE_NUMBER_KEY],
                    tag=id_,
                )
            )

        return errors
