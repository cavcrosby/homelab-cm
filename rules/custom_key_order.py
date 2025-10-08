"""Implementation of the custom-key-order rule."""

from __future__ import annotations

import functools
from typing import TYPE_CHECKING, Any
from unittest import mock

import ansiblelint.rules.key_order
from ansiblelint.constants import ANNOTATION_KEYS, RULE_DOC_URL
from ansiblelint.errors import MatchError
from ansiblelint.rules.key_order import (
    KeyOrderRule,
    KeyOrderTMeta,
    task_property_sorter,
)

if TYPE_CHECKING:
    from ansiblelint.file_utils import Lintable
    from ansiblelint.utils import Task


class CustomKeyOrderRule(KeyOrderRule):
    """Rule for checking key order."""

    id = "custom-key-order"
    tags = ["homelab-cm"]
    version_changed = "1.0.0"
    _ids = {
        "custom-key-order[play]": "You can improve the play key order to: {keys}",
        "custom-key-order[task]": "You can improve the task key order to: {keys}",
    }

    @property
    def url(self) -> str:
        """Get the rule documentation url."""
        return RULE_DOC_URL + "key-order/"

    def matchplay(self, file: Lintable, data: dict[str, Any]) -> list[MatchError]:
        """Play matching method."""
        errors: list[MatchError] = []
        if file.kind != "playbook":
            return errors

        keys = [key for key in data if key not in ANNOTATION_KEYS]
        with mock.patch.object(
            ansiblelint.rules.key_order,
            "SORTER_TASKS",
            # play key order
            (
                "name",
                "hosts",
                "ansible.builtin.import_playbook",
                "tags",
                "serial",
                "vars_files",
                "vars",
                "pre_tasks",
                "roles",
                "tasks",
                "handlers",
            ),
        ):
            sorted_keys = sorted(keys, key=functools.cmp_to_key(task_property_sorter))

        if keys != sorted_keys:
            id_ = f"{self.id}[play]"
            errors.append(
                self.create_matcherror(
                    message=self._ids[id_].format(keys={", ".join(sorted_keys)}),
                    filename=file,
                    tag=id_,
                    transform_meta=KeyOrderTMeta(fixed=tuple(sorted_keys)),
                    data=data,
                ),
            )

        return errors

    def matchtask(self, task: Task, file: Lintable | None = None) -> list[MatchError]:
        """Task matching method."""
        errors: list[MatchError] = []
        keys = [key for key in task.raw_task if not key.startswith("_")]
        with mock.patch.object(
            ansiblelint.rules.key_order,
            "SORTER_TASKS",
            # task key order
            (
                "name",
                "delegate_to",
                task.action,
                "check_mode",
                "changed_when",
                "failed_when",
                "become",
                "environment",
                "register",
                "listen",
                "notify",
                "vars",
                "loop",
                "when",
                "block",
                "rescue",
                "always",
            ),
        ):
            sorted_keys = sorted(keys, key=functools.cmp_to_key(task_property_sorter))

        if keys != sorted_keys:
            id_ = f"{self.id}[task]"
            errors.append(
                self.create_matcherror(
                    message=self._ids[id_].format(keys={", ".join(sorted_keys)}),
                    filename=file,
                    lineno=task.line,
                    tag=id_,
                    transform_meta=KeyOrderTMeta(fixed=tuple(sorted_keys)),
                ),
            )

        return errors
