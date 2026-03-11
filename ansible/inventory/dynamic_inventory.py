#!/usr/bin/env python3

import json
import subprocess

try:
    ip = subprocess.check_output(
        ["terraform", "output", "-raw", "instance_ip"],
        cwd="../../infra"
    ).decode("utf-8").strip()

    inventory = {
        "minikube": {
            "hosts": [ip]
        },
        "_meta": {
            "hostvars": {
                ip: {
                    "ansible_user": "ubuntu",
                    "ansible_ssh_private_key_file": "~/.ssh/id_rsa"
                }
            }
        }
    }

    print(json.dumps(inventory))

except:
    print(json.dumps({}))
