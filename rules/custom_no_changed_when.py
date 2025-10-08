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
    """Rule for checking changed_when in command-like tasks."""

    id = "custom-no-changed-when"
    tags = ["homelab-cm"]
    version_changed = "1.0.0"

    @property
    def url(self) -> str:
        """Get the rule documentation url."""
        return RULE_DOC_URL + "no-changed-when/"

    def matchtask(self, task: Task, file: Lintable | None = None) -> list[MatchError]:
        """Task matching method."""
        errors: list[MatchError] = []
        errors += super().matchtask(task, file)
        for error in errors:
            error.message = (
                "Use the following approach to determine change in command-like tasks,"
                " https://github.com/cavcrosby/homelab-cm/commit/d627eea."
            )

        return errors
