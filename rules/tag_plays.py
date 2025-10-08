"""Implementation of the tag-plays rule."""

from __future__ import annotations

from typing import TYPE_CHECKING

from ansiblelint.rules import AnsibleLintRule

if TYPE_CHECKING:
    from typing import Any

    from ansiblelint.errors import MatchError
    from ansiblelint.file_utils import Lintable


class TagPlaysRule(AnsibleLintRule):
    """Rule for checking tag(s) on plays."""

    id = "tag-plays"
    description = "Append playbook plays with at least one tag."
    tags = ["homelab-cm"]
    version_changed = "1.0.0"

    def matchplay(self, file: Lintable, data: dict[str, Any]) -> list[MatchError]:
        """Play matching method."""
        errors: list[MatchError] = []
        if file.kind != "playbook":
            return errors

        if not data.get("tags"):
            errors.append(
                self.create_matcherror(
                    message=self.description,
                    filename=file,
                    tag=self.id,
                    data=data,
                )
            )

        return errors
