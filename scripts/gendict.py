#!/usr/bin/env python3
"""Creates the Ansible tasks' name dictionary."""

import sys
from pathlib import Path

from ansiblelint.config import Options
from ansiblelint.rules import RulesCollection
from ansiblelint.runner import Runner
from ansiblelint.utils import get_lintables, task_in_list
from spellchecker import SpellChecker  # type: ignore # spellchecker stubs don't exist

spell_checker, unknown_words = SpellChecker(), set()
for lintable in Runner(
    *get_lintables(Options()), rules=RulesCollection([Path("./rules")])
).lintables:
    if (
        lintable.kind in ["handlers", "tasks", "playbook"]
        and str(lintable.path)
        # do not add unknown words from these lintables
        not in ("tests/rules/playbooks/name_word_misspelled_fail.yml")
    ):
        for task in task_in_list(lintable.data, lintable, lintable.kind):
            if task.name:
                for unknown_word in spell_checker.unknown(
                    spell_checker.split_words(task.name)
                ):
                    unknown_words.add(unknown_word)

with open(Path("./docs/dictionary.txt"), "w") as file:
    for unknown_word in sorted(unknown_words):
        file.write(f"{unknown_word}\n")

sys.exit(0)
