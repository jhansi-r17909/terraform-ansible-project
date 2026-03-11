#!/usr/bin/env python3
import json
import os
import sys

import boto3


def _get_env(name, default):
    value = os.environ.get(name)
    return value if value else default


def main():
    if "--list" not in sys.argv:
        print(json.dumps({}))
        return 0

    region = _get_env("AWS_REGION", _get_env("AWS_DEFAULT_REGION", "eu-north-1"))
    tag_key = _get_env("INVENTORY_TAG_KEY", "Project")
    tag_value = _get_env("INVENTORY_TAG_VALUE", "minikube-host")
    ansible_user = _get_env("ANSIBLE_USER", "ec2-user")

    ec2 = boto3.client("ec2", region_name=region)
    response = ec2.describe_instances(
        Filters=[
            {"Name": f"tag:{tag_key}", "Values": [tag_value]},
            {"Name": "instance-state-name", "Values": ["running"]},
        ]
    )

    hosts = []
    hostvars = {}
    for reservation in response.get("Reservations", []):
        for instance in reservation.get("Instances", []):
            public_ip = instance.get("PublicIpAddress")
            if not public_ip:
                continue
            hosts.append(public_ip)
            hostvars[public_ip] = {
                "ansible_user": ansible_user,
                "ansible_python_interpreter": "/usr/bin/python3",
            }

    inventory = {
        "minikube": {"hosts": hosts},
        "_meta": {"hostvars": hostvars},
    }

    print(json.dumps(inventory))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
