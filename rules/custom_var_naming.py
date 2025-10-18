"""Implementation of the custom-var-naming rule."""

from __future__ import annotations

from typing import TYPE_CHECKING

from ansiblelint.constants import RULE_DOC_URL
from ansiblelint.errors import MatchError
from ansiblelint.rules.var_naming import (
    VariableNamingRule,
)

if TYPE_CHECKING:
    from typing import Any

    from ansiblelint.file_utils import Lintable
    from ansiblelint.utils import Task


class CustomVariableNamingRule(VariableNamingRule):
    """Rule for checking variable names."""

    id = "custom-var-naming"
    tags = ["homelab-cm"]
    version_changed = "1.0.0"
    _ids = {
        "custom-var-naming[no-reserved]": "Use a trailing underscore to avoid conflicts with an Ansible keyword ({keyword}).",  # noqa E501
    }

    @property
    def url(self) -> str:
        """Get the rule documentation url."""
        return RULE_DOC_URL + "var-naming/"

    def matchplay(self, file: Lintable, data: dict[str, Any]) -> list[MatchError]:
        """Play matching method."""
        errors: list[MatchError] = []
        errors += super().matchplay(file, data)
        for error in errors:
            if error.tag == "var-naming[no-reserved]":
                id_ = f"{self.id}[no-reserved]"
                error.tag = id_
                error.message = self._ids[id_].format(
                    keyword=error.message[
                        error.message.find("(") + 1 : error.message.find(")")
                    ]
                )

        return errors

    def matchtask(self, task: Task, file: Lintable | None = None) -> list[MatchError]:
        """Task matching method."""
        errors: list[MatchError] = []
        errors += super().matchtask(task, file)
        for error in errors:
            if error.tag == "var-naming[no-reserved]":
                id_ = f"{self.id}[no-reserved]"
                error.tag = id_
                error.message = self._ids[id_].format(
                    keyword=error.message[
                        error.message.find("(") + 1 : error.message.find(")")
                    ]
                )

        return errors

    def matchyaml(self, file: Lintable) -> list[MatchError]:
        """YAML matching method."""
        errors: list[MatchError] = []
        errors += super().matchyaml(file)
        for error in errors:
            if error.tag == "var-naming[no-reserved]":
                id_ = f"{self.id}[no-reserved]"
                error.tag = id_
                error.message = self._ids[id_].format(
                    keyword=error.message[
                        error.message.find("(") + 1 : error.message.find(")")
                    ]
                )

        return errors
