import sys

import yaml

from src.check_new_version import CheckNewVersion
from src.get_unity_download_hash import get_unity_download_hash


def generate_versions_from_unity_website(versions):
    for version in versions:
        try:
            print('# generate_version_from_unity_website', version)
            print(generate_version_from_unity_website(version))
        except Exception as e:
            print('#', e)
            pass


def generate_version_from_unity_website(version):
    download_url_hash = get_unity_download_hash(version)
    check = CheckNewVersion()
    unity_version_object = check.generate_unity_version_block({
        'version': version
    }, download_url_hash=download_url_hash)
    return yaml.dump(unity_version_object)


if __name__ == '__main__':
    versions = sys.argv[1:]
    if len(versions) < 1:
        print('usage: generate_versions_from_unity_website.py 2018.4.7f1 2019.3.0f1')
    else:
        generate_versions_from_unity_website(versions)
