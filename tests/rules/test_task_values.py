"""Tests for the task_values module."""

from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING

import pytest

from rules.task_values import TaskValuesRule

if TYPE_CHECKING:
    from ansiblelint.testing import RunFromText


@pytest.mark.parametrize(
    "rule_runner",
    (TaskValuesRule,),
    indirect=["rule_runner"],
)
def test_shell_options_fail(rule_runner: RunFromText) -> None:
    """Test that task-values[shell-options] finds errors."""
    errors = rule_runner.run(Path("./tests/rules/playbooks/shell_options_fail.yml"))
    assert len(errors) == 2
    for error in errors:
        assert error.tag == "task-values[shell-options]"


@pytest.mark.parametrize(
    "rule_runner",
    (TaskValuesRule,),
    indirect=["rule_runner"],
)
def test_name_word_misspelled_fail(rule_runner: RunFromText) -> None:
    """Test that task-values[name-word-misspelled] finds errors."""
    errors = rule_runner.run(
        Path("./tests/rules/playbooks/name_word_misspelled_fail.yml")
    )
    assert len(errors) == 1
    for error in errors:
        assert error.tag == "task-values[name-word-misspelled]"


@pytest.mark.parametrize(
    "rule_runner",
    (TaskValuesRule,),
    indirect=["rule_runner"],
)
def test_system_user_verbiage_fail(rule_runner: RunFromText) -> None:
    """Test that task-values[system-user-verbiage] finds errors."""
    errors = rule_runner.run(
        Path("./tests/rules/playbooks/system_user_verbiage_fail.yml")
    )
    assert len(errors) == 2
    for error in errors:
        assert error.tag == "task-values[system-user-verbiage]"


@pytest.mark.parametrize(
    "rule_runner",
    (TaskValuesRule,),
    indirect=["rule_runner"],
)
def test_hardcode_users_name_fail(rule_runner: RunFromText) -> None:
    """Test that task-values[hardcode-users-name] finds errors."""
    errors = rule_runner.run(
        Path("./tests/rules/playbooks/hardcode_users_name_fail.yml")
    )
    assert len(errors) == 1
    for error in errors:
        assert error.tag == "task-values[hardcode-users-name]"


@pytest.mark.parametrize(
    "rule_runner",
    (TaskValuesRule,),
    indirect=["rule_runner"],
)
def test_append_distro_fail(rule_runner: RunFromText) -> None:
    """Test that task-values[append-distro] finds errors."""
    errors = rule_runner.run(Path("./tests/rules/playbooks/append_distro_fail.yml"))
    assert len(errors) == 4
    for error in errors:
        assert error.tag == "task-values[append-distro]"


@pytest.mark.parametrize(
    "rule_runner",
    (TaskValuesRule,),
    indirect=["rule_runner"],
)
def test_pkg_names_order_fail(rule_runner: RunFromText) -> None:
    """Test that task-values[pkg-names-order] finds errors."""
    errors = rule_runner.run(Path("./tests/rules/playbooks/pkg_names_order_fail.yml"))
    assert len(errors) == 1
    for error in errors:
        assert error.tag == "task-values[pkg-names-order]"


@pytest.mark.parametrize(
    "rule_runner",
    (TaskValuesRule,),
    indirect=["rule_runner"],
)
def test_fqcn_in_filter_fail(rule_runner: RunFromText) -> None:
    """Test that task-values[fqcn-in-filter] finds errors."""
    errors = rule_runner.run(Path("./tests/rules/playbooks/fqcn_in_filter_fail.yml"))
    assert len(errors) == 6
    for error in errors:
        assert error.tag == "task-values[fqcn-in-filter]"

    errors = rule_runner.run(
        Path("./tests/rules/roles/test/defaults/fqcn_in_filter_fail.yml")
    )
    assert len(errors) == 4
    for error in errors:
        assert error.tag == "task-values[fqcn-in-filter]"


@pytest.mark.parametrize(
    "rule_runner",
    (TaskValuesRule,),
    indirect=["rule_runner"],
)
def test_yaml_sequences_fail(rule_runner: RunFromText) -> None:
    """Test that task-values[yaml-sequences] finds errors."""
    errors = rule_runner.run(Path("./tests/rules/playbooks/yaml_sequences_fail.yml"))
    assert len(errors) == 1
    for error in errors:
        assert error.tag == "task-values[yaml-sequences]"


@pytest.mark.parametrize(
    "rule_runner",
    (TaskValuesRule,),
    indirect=["rule_runner"],
)
def test_no_var_name_fail(rule_runner: RunFromText) -> None:
    """Test that task-values[no-var-name] finds errors."""
    errors = rule_runner.run(Path("./tests/rules/playbooks/no_var_name_fail.yml"))
    assert len(errors) == 1
    for error in errors:
        assert error.tag == "task-values[no-var-name]"


@pytest.mark.parametrize(
    "rule_runner",
    (TaskValuesRule,),
    indirect=["rule_runner"],
)
def test_append_systemd_unit_fail(rule_runner: RunFromText) -> None:
    """Test that task-values[append-systemd-unit] finds errors."""
    errors = rule_runner.run(
        Path("./tests/rules/playbooks/append_systemd_unit_fail.yml")
    )
    assert len(errors) == 1
    for error in errors:
        assert error.tag == "task-values[append-systemd-unit]"
