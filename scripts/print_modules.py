#!/usr/bin/env python3
"""Prints all the Ansible task modules used in this codebase."""

from __future__ import annotations

import sys

from ansiblelint.config import Options
from ansiblelint.rules import RulesCollection
from ansiblelint.runner import Runner
from ansiblelint.skip_utils import is_nested_task
from ansiblelint.utils import get_lintables, task_in_list


def main() -> None:
    """Start the main program execution."""
    modules = set()
    for lintable in Runner(
        *get_lintables(Options()), rules=RulesCollection()
    ).lintables:
        if lintable.kind in ["handlers", "tasks", "playbook"]:
            for task in task_in_list(lintable.data, lintable, lintable.kind):
                if not is_nested_task(task):
                    modules.add(task.action)

    for module in sorted(modules):
        print(module)


if __name__ == "__main__":
    main()
    sys.exit(0)
