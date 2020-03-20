import yaml

from src.check_new_version import CheckNewVersion
from src.get_unity_download_hash import get_unity_download_hash

if __name__ == '__main__':

    versions = [
        '2019.2.18f1',
        '2019.2.13f1',
        '2019.2.10f1',
        '2019.2.7f1',
        '2019.2.6f1',
        '2019.2.3f1',
        '2019.2.1f1',
        '2019.2.0f1',
        '2019.1.13f1',
        '2019.1.11f1',
        '2019.1.10f1',
        '2019.1.9f1',
        '2019.1.8f1',
        '2019.1.5f1',
        '2018.4.7f1',
        '2018.4.4f1',
        '2018.4.3f1',
        '2018.3.13f1',
        '2018.3.10f1',
        '2018.3.9f1',
        '2018.3.8f1',
        '2018.3.6f1',
        '2018.3.5f1',
        '2018.2.8f1',
        '2018.1.9f2',
        '2018.1.8f1',
        '2018.1.7f1',
        '2018.1.4f1',
        '2018.1.1f1',
    ]

    for version in versions:
        try:
            download_url_hash = get_unity_download_hash(version)
            check = CheckNewVersion()
            unity_version_object = check.generate_unity_version_block({
                'version': version
            }, download_url_hash=download_url_hash)
            print(yaml.dump(unity_version_object))
        except Exception:
            pass
