#!/usr/bin/env python3
#-*- coding: utf-8 -*-
#
# Print a dependency tree, starting at the leaves.
#
# PROOF OF CONCEPT ONLY. Will not eat your data, but has limited functionality
# and grew organically while trying out ways to format the data. Global state
# everywhere.
#
# Example usage:
#   $ ./tw_deptree.py
#   ID  Description
#   1   Task One
#   2     Task Two
#   3       Task Three
#
# Limiting to certain tasks not implemented. grep can be used to show only
# pending and waiting tasks (i.e. those with an ID):
#   $ ./tw_deptree.py | grep -v '^-'

from collections import defaultdict
import json
import subprocess
import sys

p = subprocess.Popen(["task", "rc.json.array=1", "export"],
                     stdout=subprocess.PIPE)
tasks = json.loads(p.communicate()[0].decode("utf-8"))

for t in tasks:
    if t["id"] == 0:
        t["id"] = "-"

seen = set()
dependencies = defaultdict(list)


def showdeps(deps, depth=None):
    if depth is None:
        depth = 1
    for t in deps:
        print_task(t, depth)
        if t in seen:
            # Skip subtrees we have seen already
            if t in dependencies:
                print("{0}(...)".format("  "*(depth+3)))
            continue
        seen.add(t)
        if t in dependencies:
            showdeps(dependencies[t], depth + 1)


def tw_get(uuid, attribute):
    try:
        return next(t[attribute] for t in tasks if t["uuid"] == uuid)
    except KeyError:
        # Mirakel seems to not set a modified date, work around this.
        # Since this is already a pretty hacky script, adding a special
        # case here doesn't seem too bad. :)
        if attribute == "modified":
            return tw_get(uuid, "entry")
        else:
            raise


def print_task(uuid, depth=None):
    if depth is None:
        depth = 0
    print("{0:<3} {1}{2}".format(tw_get(uuid, "id"),
                                 "  "*depth,
                                 tw_get(uuid, "description")))


print("ID  Description")
for t in tasks:
    if "depends" in t:
        for d in t["depends"].split(","):
            dependencies[d].append(t["uuid"])

for k, v in sorted(dependencies.items(),
                   key=lambda x: tw_get(x[0], "modified")):
    if not any(x for x in dependencies.values() if k in x):
        print_task(k)
        showdeps(v)
