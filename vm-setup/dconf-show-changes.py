#!/usr/bin/env python3

import subprocess

DUMP_FILE = "dconf-changes.dump"

def dump_dconf_settings():
    # Dump all non-default dconf settings to a file
    with open(DUMP_FILE, "w") as f:
        output = subprocess.check_output(["dconf", "dump", "/"]).decode("utf-8")
        lines = output.split("\n")
        schema = None
        settings = {}
        for line in lines:
            if line.startswith("["):
                if schema:
                    # Output the schema block if it has non-default settings
                    if settings:
                        f.write(schema + "\n")
                        for setting in settings:
                            f.write(setting + "\n")
                        f.write("\n")  # Add an empty line after the block
                    settings = {}
                schema = line
            else:
                key, value = line.split("=")
                default_value = subprocess.check_output(["dconf", "read", schema.strip() + "/" + key.strip()]).decode("utf-8").strip()
                if default_value != value:
                    settings[key + "=" + value] = True
        if settings:
            f.write(schema + "\n")
            for setting in settings:
                f.write(setting + "\n")

    print("Non-default dconf settings have been dumped to", DUMP_FILE)

if __name__ == "__main__":
    dump_dconf_settings()
