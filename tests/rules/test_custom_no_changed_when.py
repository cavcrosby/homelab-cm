"""Tests for the custom_no_changed_when module."""

from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING

import pytest

from rules.custom_no_changed_when import CustomNoChangedWhenRule

if TYPE_CHECKING:
    from ansiblelint.testing import RunFromText


@pytest.mark.parametrize(
    "rule_runner",
    (CustomNoChangedWhenRule,),
    indirect=["rule_runner"],
)
def test_custom_no_changed_when_fail(rule_runner: RunFromText) -> None:
    """Test that custom-no-changed-when finds errors."""
    errors = rule_runner.run(
        Path("./tests/rules/playbooks/custom_no_changed_when_fail.yml")
    )
    assert len(errors) == 1
    for error in errors:
        assert error.tag == "custom-no-changed-when"
