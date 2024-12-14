"""Tests for the custom_key_order module."""

from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING

import pytest

from rules.custom_key_order import CustomKeyOrderRule

if TYPE_CHECKING:
    from ansiblelint.testing import RunFromText


@pytest.mark.parametrize(
    "rule_runner",
    (CustomKeyOrderRule,),
    indirect=["rule_runner"],
)
def test_play_fail(rule_runner: RunFromText) -> None:
    """Test that custom-key-order[play] finds errors."""
    errors = rule_runner.run(
        Path("./tests/rules/playbooks/custom_key_order_play_fail.yml")
    )
    assert len(errors) == 1
    for error in errors:
        assert error.tag == "custom-key-order[play]"


@pytest.mark.parametrize(
    "rule_runner",
    (CustomKeyOrderRule,),
    indirect=["rule_runner"],
)
def test_task_fail(rule_runner: RunFromText) -> None:
    """Test that custom-key-order[task] finds errors."""
    errors = rule_runner.run(
        Path("./tests/rules/playbooks/custom_key_order_task_fail.yml")
    )
    assert len(errors) == 2
    for error in errors:
        assert error.tag == "custom-key-order[task]"
