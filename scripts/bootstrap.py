#!/usr/bin/env python3
"""Bootstraps an AWS account to be managed by OpenTofu."""

from __future__ import annotations

import argparse
import hashlib
import logging
import os
import sys
from typing import TYPE_CHECKING

import boto3

if TYPE_CHECKING:
    from mypy_boto3_s3.service_resource import Bucket

logger = logging.getLogger(__name__)


def main(args: argparse.Namespace) -> None:
    """Start the main program execution."""
    logging.basicConfig(level=os.getenv("LOGLEVEL", logging.INFO))
    bucket: Bucket = boto3.resource("s3").Bucket(
        f"{hashlib.sha256(args.account_name.encode()).hexdigest()[:12]}-homelab-cm"
    )

    if args.undo:
        bucket.object_versions.delete()
        bucket.delete()
    else:
        bucket.create()
        bucket.Versioning().enable()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description=__doc__,
        allow_abbrev=False,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "-u",
        "--undo",
        action="store_true",
        help="undoes changes made",
    )
    parser.add_argument(
        "account_name",
        help="specify the account name",
    )

    main(parser.parse_args())
    sys.exit(0)
