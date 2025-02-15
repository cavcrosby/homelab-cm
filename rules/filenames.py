"""Implementation of the filenames rule."""

from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING

from ansiblelint.rules import AnsibleLintRule

if TYPE_CHECKING:
    from ansiblelint.errors import MatchError
    from ansiblelint.file_utils import Lintable


class FileNamesRule(AnsibleLintRule):
    """Rule for checking Ansible yaml file names."""

    id = "filenames"
    description = "Ansible yaml file names must follow the set conventions."
    tags = ["homelab-cm"]
    _ids = {
        "filenames[append-yml-ext]": "Append a file extension of '.yml' to all Ansible yaml files ({filename}).",  # noqa E501
        "filenames[no-dashes]": "Do not use dashes in Ansible yaml's file names, instead use underscores ({filename}).",  # noqa E501
        "filenames[no-underscores-jinja]": "Do not use underscores in Jinja template's file names, instead use dashes ({filename}).",  # noqa E501
    }

    def matchyaml(self, file: Lintable) -> list[MatchError]:
        """YAML matching method."""
        errors: list[MatchError] = []
        filename = Path(file.path).name
        if file.kind and file.base_kind == "text/yaml":
            if ".yml" not in filename:
                id_ = f"{self.id}[append-yml-ext]"
                errors.append(
                    self.create_matcherror(
                        message=self._ids[id_].format(filename=filename),
                        filename=file,
                        tag=id_,
                    )
                )

            if "-" in filename:
                id_ = f"{self.id}[no-dashes]"
                errors.append(
                    self.create_matcherror(
                        message=self._ids[id_].format(filename=filename),
                        filename=file,
                        tag=id_,
                    )
                )

        if (
            file.kind == "jinja2"  # type: ignore # file.kind: FileType type can include jinja2
            and "_" in filename
            and str(file.path)
            not in (
                # do not apply rule for these lintables
                "playbooks/templates/en_US.UTF-8.j2",
                "playbooks/templates/pam_access.conf.j2",
                "roles/k8s_node/templates/br_netfilter.conf.j2",
            )
        ):
            id_ = f"{self.id}[no-underscores-jinja]"
            errors.append(
                self.create_matcherror(
                    message=self._ids[id_].format(filename=filename),
                    filename=file,
                    tag=id_,
                )
            )

        return errors
