"""Implementation of the custom-no-changed-when rule."""

from __future__ import annotations

from typing import TYPE_CHECKING

from ansiblelint.constants import RULE_DOC_URL
from ansiblelint.errors import MatchError
from ansiblelint.rules.no_changed_when import (
    CommandHasChangesCheckRule,
)

if TYPE_CHECKING:
    from ansiblelint.file_utils import Lintable
    from ansiblelint.utils import Task


class CustomNoChangedWhenRule(CommandHasChangesCheckRule):
    """Rule for checking changed_when in tasks."""

    id = "custom-no-changed-when"
    tags = ["homelab-cm"]
    version_changed = "1.0.0"
    _ids = {
        "custom-no-changed-when[command-like]": "Use the following approach to determine change in command-like tasks, https://github.com/cavcrosby/homelab-cm/commit/d627eea.",  # noqa E501
        "custom-no-changed-when[uri]": "Requests to web services without downloading should define when things have changed.",  # noqa E501
    }

    @property
    def url(self) -> str:
        """Get the rule documentation url."""
        return RULE_DOC_URL + "no-changed-when/"

    def matchtask(self, task: Task, file: Lintable | None = None) -> list[MatchError]:
        """Task matching method."""
        errors: list[MatchError] = []
        errors += super().matchtask(task, file)
        for error in errors:
            id_ = f"{self.id}[command-like]"
            error.tag = id_
            error.message = self._ids[id_]

        if (
            task.action == "ansible.builtin.uri"
            and not task.args.get("dest")
            and "changed_when" not in task
        ):
            id_ = f"{self.id}[uri]"
            errors.append(
                self.create_matcherror(
                    message=self._ids[id_],
                    filename=file,
                    lineno=task.line,
                    tag=id_,
                )
            )

        return errors
