"""Tests for the filenames module."""

from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING

import pytest

from rules.filenames import FileNamesRule

if TYPE_CHECKING:
    from ansiblelint.testing import RunFromText


@pytest.mark.parametrize(
    "rule_runner",
    (FileNamesRule,),
    indirect=["rule_runner"],
)
def test_append_yml_ext_fail(rule_runner: RunFromText) -> None:
    """Test that filenames[append-yml-ext] finds errors."""
    errors = rule_runner.run(Path("./tests/rules/playbooks/append_yml_ext_fail.yaml"))
    assert len(errors) == 1
    for error in errors:
        assert error.tag == "filenames[append-yml-ext]"


@pytest.mark.parametrize(
    "rule_runner",
    (FileNamesRule,),
    indirect=["rule_runner"],
)
def test_no_dashes_fail(rule_runner: RunFromText) -> None:
    """Test that filenames[no-dashes] finds errors."""
    errors = rule_runner.run(Path("./tests/rules/playbooks/no-dashes-fail.yml"))
    assert len(errors) == 1
    for error in errors:
        assert error.tag == "filenames[no-dashes]"


@pytest.mark.parametrize(
    "rule_runner",
    (FileNamesRule,),
    indirect=["rule_runner"],
)
def test_no_underscores_jinja_fail(rule_runner: RunFromText) -> None:
    """Test that filenames[no-underscores-jinja] finds errors."""
    errors = rule_runner.run(
        Path("./tests/rules/templates/no_underscores_jinja_fail.j2")
    )
    assert len(errors) == 1
    for error in errors:
        assert error.tag == "filenames[no-underscores-jinja]"
