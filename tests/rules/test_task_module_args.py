"""Tests for the task_module_args module."""

from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING

import pytest

from rules.task_module_args import TaskModuleAliasesRule

if TYPE_CHECKING:
    from ansiblelint.testing import RunFromText


@pytest.mark.parametrize(
    "rule_runner",
    (TaskModuleAliasesRule,),
    indirect=["rule_runner"],
)
def test_checksum_param_fail(rule_runner: RunFromText) -> None:
    """Test that task-module-args[checksum-param] finds errors."""
    errors = rule_runner.run(Path("./tests/rules/playbooks/checksum_param_fail.yml"))
    assert len(errors) == 1
    for error in errors:
        assert error.tag == "task-module-args[checksum-param]"
