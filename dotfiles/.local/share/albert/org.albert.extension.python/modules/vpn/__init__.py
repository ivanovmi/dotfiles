# -*- coding: utf-8 -*-

"""
VPN toggle based on nmcli
"""

from albertv0 import FuncAction, Item, iconLookup
import subprocess

__iid__ = "PythonInterface/v0.1"
__prettyname__ = "VPN Toggle"
__version__ = "1.0"
__trigger__ = "vpn "
__author__ = "mivanov"
__dependencies__ = ["nmcli"]

iconPath = iconLookup("vpn")


def filter_vpn(active=False):
    nmcli_list = ["nmcli", "-g", "name,type", "connection", "show"]
    if active:
        nmcli_list.append("--active")
    nmcli_out = subprocess.check_output(nmcli_list,
                                        universal_newlines=True).split("\n")
    return [''.join(c.split(":")[:-1]) for c in nmcli_out
            if c.split(":")[-1] == "vpn"]


def toggle_vpn(vpn_name, active_vpns):
    action = "down" if vpn_name in active_vpns else "up"
    subprocess.call(["nmcli", "connection", action, vpn_name])


def handleQuery(query):
    if not query.isTriggered:
        return None
    items = []
    vpn_names = filter_vpn()
    active_vpn_names = filter_vpn(active=True)
    for vpn in vpn_names:
        st = "Disable" if vpn in active_vpn_names else "Enable"
        items.append(Item(
            id=__prettyname__,
            icon=iconPath,
            text=vpn,
            subtext="{} VPN connection".format(st),
            actions=[
                FuncAction("Toggle VPN connection",
                           lambda: toggle_vpn(vpn, active_vpn_names))
            ]
        ))
    return items
