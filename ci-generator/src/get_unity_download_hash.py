#!/usr/bin/env python3
import re
import sys

import requests


class NotFoundException(Exception):
    pass

def get_unity_download_hash(version_key):
    unity_version_regex = re.compile("(\d*\.\d*\.\d*)([a-z]*\d*)")
    match = unity_version_regex.match(version_key)
    version = match.group(1)
    url = f"https://unity3d.com/unity/whats-new/{version}"
    response = requests.get(url)

    if response.status_code == 404:
        raise NotFoundException(f"{url} returned {response.status_code} status code")
    elif response.status_code != 200:
        raise Exception(f"{url} returned {response.status_code} status code")

    response_content = response.content.decode("utf-8")

    try:
        hash_from_url_regex = re.compile("(.*/download/)(.{12})/.*")
        match = hash_from_url_regex.search(response_content)
        result = match.group(2)
    except AttributeError as e:
        hash_from_url_regex = re.compile("(.*Changeset:</span>.*\s.*)([a-zA-Z0-9]{12}).*")
        match = hash_from_url_regex.search(response_content)
        result = match.group(2)
    return result


if __name__ == "__main__":
    version = sys.argv[1]
    get_unity_download_hash(version)
