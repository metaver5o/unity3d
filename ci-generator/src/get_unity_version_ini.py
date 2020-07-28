#!/usr/bin/env python3
import configparser
import sys

import requests


def get_unity_ini(version, hash):
    url = f"https://beta.unity3d.com/download/{hash}/unity-{version}-linux.ini"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"{url} returned {response.status_code} status code")

    response_content = response.content.decode("utf-8")

    config = configparser.ConfigParser()
    config.read_string(response_content)
    return config


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: get_unity_ini.py 2020.1.0b9 2ab9c4179772")
    version = sys.argv[1]
    hash = sys.argv[2]
    print(get_unity_ini(version, hash))
