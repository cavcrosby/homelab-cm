"""Tests for the tag_plays module."""

from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING

import pytest

from rules.tag_plays import TagPlaysRule

if TYPE_CHECKING:
    from ansiblelint.testing import RunFromText


@pytest.mark.parametrize(
    "rule_runner",
    (TagPlaysRule,),
    indirect=["rule_runner"],
)
def test_checksum_param_fail(rule_runner: RunFromText) -> None:
    """Test that tag-plays finds errors."""
    errors = rule_runner.run(Path("./tests/rules/playbooks/tag_plays_fail.yml"))
    assert len(errors) == 1
    for error in errors:
        assert error.tag == "tag-plays"
