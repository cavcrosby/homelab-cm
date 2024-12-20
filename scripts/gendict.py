#!/usr/bin/env python3
"""Creates the Ansible tasks' name dictionary."""

from __future__ import annotations

import sys
from pathlib import Path

from ansiblelint.config import Options
from ansiblelint.rules import RulesCollection
from ansiblelint.runner import Runner
from ansiblelint.utils import get_lintables, task_in_list
from spellchecker import SpellChecker  # type: ignore # spellchecker stubs don't exist

spell_checker = SpellChecker()


def main() -> None:
    """Start the main program execution."""
    unknown_words = set()
    for lintable in Runner(
        *get_lintables(Options()), rules=RulesCollection([Path("./rules")])
    ).lintables:
        if lintable.kind in ["handlers", "tasks", "playbook"]:
            for task in task_in_list(lintable.data, lintable, lintable.kind):
                if task.name:
                    for unknown_word in spell_checker.unknown(
                        spell_checker.split_words(task.name)
                    ):
                        unknown_words.add(unknown_word)

    with open(Path("./docs/dictionary.txt"), "w") as file:
        for unknown_word in sorted(unknown_words):
            file.write(f"{unknown_word}\n")


if __name__ == "__main__":
    main()
    sys.exit(0)
