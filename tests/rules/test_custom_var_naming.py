"""Tests for the custom_var_naming module."""

from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING

import pytest

from rules.custom_var_naming import CustomVariableNamingRule

if TYPE_CHECKING:
    from ansiblelint.testing import RunFromText


@pytest.mark.parametrize(
    "rule_runner",
    (CustomVariableNamingRule,),
    indirect=["rule_runner"],
)
def test_no_reserved_fail(rule_runner: RunFromText) -> None:
    """Test that custom-var-naming[no-reserved] finds errors."""
    errors = rule_runner.run(Path("./tests/rules/playbooks/no_reserved_fail.yml"))
    assert len(errors) == 2
    for error in errors:
        assert error.tag == "custom-var-naming[no-reserved]"

    errors = rule_runner.run(
        Path("./tests/rules/roles/test/defaults/no_reserved_fail.yml")
    )
    assert len(errors) == 1
    for error in errors:
        assert error.tag == "custom-var-naming[no-reserved]"
