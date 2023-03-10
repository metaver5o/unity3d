#!/usr/bin/env python3
import sys

import yaml
from src.check_new_version import CheckNewVersion
from src.get_unity_download_hash import get_unity_download_hash, NotFoundException


def generate_versions_from_unity_website(unity_versions):
    for version in unity_versions:
        try:
            print("# generate_version_from_unity_website", version)
            print(generate_version_from_unity_website_yaml(version))
        except Exception as e:
            print("#", e)
            pass


def generate_version_from_unity_website_yaml(unity_version):
    unity_version_object = get_unity_version_object_from_website(unity_version)
    return yaml.dump(unity_version_object)


def get_unity_version_object_from_website(unity_version):
    try:
        download_url_hash = get_unity_download_hash(unity_version)
    except NotFoundException:
        try:
            download_url_hash = get_unity_download_hash(unity_version[:-1])
        except NotFoundException:
            try:
                download_url_hash = get_unity_download_hash(unity_version[:-1][:-1])
            except NotFoundException:
                try:
                    download_url_hash = get_unity_download_hash(unity_version[:-1][:-1][:-1])
                except NotFoundException:
                    download_url_hash = get_unity_download_hash(unity_version[:-1][:-1][:-1][:-1])

    check = CheckNewVersion()
    unity_version_object = check.generate_unity_version_configuration(
        {"version": unity_version}, download_url_hash=download_url_hash
    )
    return unity_version_object


if __name__ == "__main__":
    versions = sys.argv[1:]
    if len(versions) < 1:
        print("usage: generate_versions_from_unity_website.py 2018.4.7f1 2019.3.0f1")
    else:
        generate_versions_from_unity_website(versions)
