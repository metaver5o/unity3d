import hashlib
import os
import re

import yaml
from requests import get

DEFAULT_RELEASE_KEY = 'official'


class CheckNewVersion(object):
    release_url = 'https://public-cdn.cloud.unity3d.com/hub/prod/releases-linux.json'

    @staticmethod
    def get_parent_full_path(file_name):
        # TODO: move to utils
        base_dirname = os.path.join(os.path.dirname(os.path.realpath(__file__)), '..')
        return os.path.join(base_dirname, file_name)

    @staticmethod
    def get_versions_dict(unity_versions):
        with open(unity_versions, "r") as f:
            unity_versions = yaml.safe_load(f.read())
        if unity_versions is None:
            unity_versions = {}
        return unity_versions

    def get_all_unity_versions(self):
        return list(
            {
                **self.get_versions_dict(self.get_parent_full_path("unity_versions.yml")),
                **self.get_versions_dict(self.get_parent_full_path("unity_versions.old.yml")),
            }.keys()
        )

    def get_latest_unity_releases(self, release_key=DEFAULT_RELEASE_KEY):
        releases = self.get_releases()
        filtered_releases = []
        for release in releases[release_key]:
            filtered_releases.append(release['version'])
        return filtered_releases

    def get_releases(self):
        return get(self.release_url).json()

    def generate_unity_version_block(self, detailed_missing_version, download_url_hash=None):
        original_download_url = detailed_missing_version.get('downloadUrl')
        version_key = detailed_missing_version.get('version')
        # https://regex101.com/r/2Yzsen/1
        unity_version_regex = re.compile("(\d*\.\d*\.\d*)([a-z]*\d*)")
        match = unity_version_regex.match(version_key)
        version = match.group(1)
        build = match.group(2)
        underscore = version_key.replace('.', '_')
        if download_url_hash is None:
            download_url_hash = self.get_hash_from_download_url(original_download_url)
        download_url = f'https://beta.unity3d.com/download/{download_url_hash}/UnitySetup-{version_key}'
        sha1 = self.get_sha1_from_download_url(download_url)
        release_notes = f'https://unity3d.com/unity/whats-new/{version_key}'
        release_url = f'https://beta.unity3d.com/download/{download_url_hash}/public_download.html'

        return {
            version_key: {
                'dockerfile_name': 'unitysetup',
                'version': version,
                'underscore': underscore,
                'download_url': download_url,
                'sha1': sha1,
                'build': build,
                'release_notes': release_notes,
                'release_url': release_url
            }
        }

    @staticmethod
    def get_hash_from_download_url(original_download_url):
        # https://regex101.com/r/GvPqiH/2
        hash_pattern = re.compile("(https?://(beta|download)\.unity3d\.com\/(download|download_unity)\/)(\S{12})\/.*")
        match = hash_pattern.match(original_download_url)
        return match.group(4)

    @staticmethod
    def download_file(url, file_name):
        with open(file_name, "wb") as file:
            response = get(url)
            file.write(response.content)

    def get_sha1_from_download_url(self, download_url):
        file_name = 'UnitySetup'
        self.download_file(download_url, file_name)
        sha1 = self.sha1(file_name)
        os.remove(file_name)
        return sha1

    @staticmethod
    def sha1(file_name):
        block_size = 65536
        hashing_algorithm = hashlib.sha1()
        with open(file_name, 'rb') as afile:
            buf = afile.read(block_size)
            while len(buf) > 0:
                hashing_algorithm.update(buf)
                buf = afile.read(block_size)
        return hashing_algorithm.hexdigest()

    def output(self, release_key=DEFAULT_RELEASE_KEY):
        latest_releases = self.get_latest_unity_releases(release_key)
        current_versions = self.get_all_unity_versions()
        missing_versions = [version for version in latest_releases if version not in current_versions]

        releases = self.get_releases()

        missing_versions_details = []
        for missing_version in missing_versions:
            for release in releases[release_key]:
                if release['version'] == missing_version:
                    missing_versions_details.append(release)

        unity_version_objects = []
        for detailed_missing_version in missing_versions_details:
            unity_version_objects.append(self.generate_unity_version_block(detailed_missing_version))

        for unity_version_object in unity_version_objects:
            print(yaml.dump(unity_version_object))


if __name__ == '__main__':
    CheckNewVersion().output(release_key='beta')
    CheckNewVersion().output()
