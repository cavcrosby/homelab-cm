#!/usr/bin/env python3
"""Creates a infrastructure diagram of my homelab."""
# Standard Library Imports
import argparse
import sys

# Third Party Imports
from diagrams import Diagram
from diagrams.aws.compute import Lightsail
from diagrams.generic.network import Subnet
from diagrams.onprem.client import Client
from diagrams.onprem.compute import Server
from diagrams.onprem.network import Internet

# Local Application Imports
from pylib.argparse import CustomHelpFormatter

# constants and other program configurations
_arg_parser = argparse.ArgumentParser(
    description=__doc__,
    formatter_class=lambda prog: CustomHelpFormatter(
        prog, max_help_position=35
    ),
    allow_abbrev=False,
)


def retrieve_cmd_args():
    """Retrieve command arguments from the command line.

    Returns
    -------
    Namespace
        An object that holds attributes pulled from the command line.

    Raises
    ------
    SystemExit
        If user input is not considered valid when parsing arguments.

    """
    args = vars(_arg_parser.parse_args())
    return args


def main(args):
    """Start the main program execution."""
    with Diagram("homelab", show=False):
        gateway = Internet("gateway\nx.x.x.1")

        main_subnet = Subnet("10.10.90.0/24")

        gerald = Server("gerald\nx.x.x.3")
        ron = Client("ron\nx.x.x.50")
        dexter = Client("dexter\nx.x.x.51")
        roxanne = Client("roxanne\nx.x.x.52")

        milo = Lightsail("milo\n35.168.24.181")

        # All network communications I anticpate to be bidirectional. That
        # said, for simplifying the diagram, the direction arrows will indicate
        # the flow of data to my primary gateway for my home network(s).
        #
        # internal machines
        [gerald, ron, dexter, roxanne] >> main_subnet

        # internal subnets
        [main_subnet] >> gateway

        # external machines
        gateway << milo


if __name__ == "__main__":
    args = retrieve_cmd_args()
    main(args)
    sys.exit(0)
