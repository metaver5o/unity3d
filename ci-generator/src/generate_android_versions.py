#!/usr/bin/env python3
import configparser
import sys

import requests
import yaml

from src.generate_versions_from_unity_website import get_unity_version_object_from_website


if __name__ == "__main__":
    versions = sys.argv[1:]
    if len(versions) < 1:
        print("usage: generate_android_versions.py 2018.4.7f1 2019.3.0f1")
    else:
        for version in versions:
            try:
                print("# generate_android_versions.py", version)
                unity_version_object = get_unity_version_object_from_website(version)
                unity_version_object['base_image'] = f'gableroux/{version}'
                unity_version_object['skip_prepare_stage'] = True
                unity_version_object['build_only_these_platforms'] = 'android'
                print(yaml.dump(unity_version_object))
            except Exception as e:
                print("#", e)
                pass
