import json
import os
from unittest import TestCase, mock

import requests_mock
from src.check_new_version import CheckNewVersion
from tests import utils


class TestGitlabCiGenerator(TestCase):
    class_path = "src.check_new_version.CheckNewVersion"

    @staticmethod
    def mock_releases_json_get(mocked_request, release_file):
        with open(utils.full_path_from_relative_path(release_file), "r") as f:
            json_text = f.read()
        mocked_request.get(
            "https://public-cdn.cloud.unity3d.com/hub/prod/releases-linux.json",
            text=json_text,
        )
        return json_text

    def test_get_versions_dict(self):
        with self.subTest("test_empty.yml"):
            result = CheckNewVersion.get_versions_dict(
                utils.full_path_from_relative_path("data/test_empty.yml")
            )
            expected_result = {}
            self.assertEqual(expected_result, result)

        with self.subTest("test_unitysetup_2019.yml"):
            result = CheckNewVersion.get_versions_dict(
                utils.full_path_from_relative_path("data/test_unitysetup_2019.yml")
            )
            list_of_keys = list(result.keys())
            expected_list_of_keys = ["2019.1.3f1"]
            self.assertEqual(expected_list_of_keys, list_of_keys)

    def test_get_all_unity_versions(self):
        check_new_version = CheckNewVersion()
        with mock.patch(
            "src.check_new_version.CheckNewVersion.get_versions_dict"
        ) as mocked_get_versions_dict:
            mocked_get_versions_dict.return_value = {"test": "value"}
            result = check_new_version.get_all_unity_versions()
        expected_result = ["test"]
        self.assertEqual(expected_result, result)

    @requests_mock.mock()
    def test_get_latest_unity_releases(self, mocked_request):
        check_new_version = CheckNewVersion()
        self.mock_releases_json_get(
            mocked_request, "data/releases-linux-2019-05-30.json"
        )
        with self.subTest(
            "get_latest_unity_releases returns stable releases by default"
        ):
            result = check_new_version.get_latest_unity_releases()
            expected_result = [
                "2017.4.27f1",
                "2018.2.21f1",
                "2018.3.14f1",
                "2018.4.1f1",
                "2019.1.4f1",
            ]
            self.assertEqual(expected_result, result)
        with self.subTest(
            "get_latest_unity_releases returns 'beta' releases when passing 'beta' argument"
        ):
            result = check_new_version.get_latest_unity_releases("beta")
            expected_result = ["2019.2.0b4", "2019.3.0a3"]
            self.assertEqual(expected_result, result)

    @requests_mock.mock()
    def test_get_releases(self, mocked_request):
        check_new_version = CheckNewVersion()
        json_text = self.mock_releases_json_get(
            mocked_request, "data/releases-linux-2019-05-30.json"
        )
        response = check_new_version.get_releases()
        expected_response = json.loads(json_text)
        self.assertEqual(expected_response, response)

    def test_generate_unity_version_configuration(self):
        self.maxDiff = None
        release_key = "official"
        releases_source = "data/releases-linux-2019-05-30.json"
        release_index = 0
        with self.subTest(f"{releases_source} {release_key}[{release_index}]"):
            expected_release_result = {
                "2017.4.27f1": {
                    "build": "f1",
                    "dockerfile_name": "unitysetup",
                    "download_url": "https://beta.unity3d.com/download/0c4b856e4c6e/UnitySetup-2017.4.27f1",
                    "platforms": {"facebook": {"components": "Facebook-Games"}},
                    "release_notes": "https://unity3d.com/unity/whats-new/2017.4.27",
                    "release_url": "https://beta.unity3d.com/download/0c4b856e4c6e/public_download.html",
                    "sha1": "8dae4dd18df383a598830c6e2489cdecdcb19273",
                    "skip": True,
                    "skip_reason": "https://gitlab.com/gableroux/unity3d/issues/40",
                    "underscore": "2017_4_27f1",
                    "variables": {
                        "android": {
                            "ANDROID_NDK": "http://dl.google.com/android/repository/android-ndk-r13d-linux-x86_64.zip",
                            "ANDROID_SDK_BUILDTOOLS": "http://dl.google.com/android/repository/build-tools_r28-linux.zip",
                            "ANDROID_SDK_PLATFORM": "http://dl.google.com/android/repository/platform-28_r06.zip",
                            "ANDROID_SDK_PLATFORMTOOLS": "http://dl.google.com/android/repository/platform-tools_r28.0.3-linux.zip",
                            "ANDROID_SDK_SDKTOOLS": "http://dl.google.com/android/repository/sdk-tools-linux-4333796.zip",
                        }
                    },
                    "version": "2017.4.27",
                }
            }
            self.do_test_generate_unity_version_block(
                releases_source, release_key, release_index, expected_release_result
            )

        release_key = "official"
        releases_source = "data/releases-linux-2020-02-18.json"
        release_index = 2
        with self.subTest(f"{releases_source} {release_key}[{release_index}]"):
            expected_release_result = {
                "2019.2.21f1": {
                    "build": "f1",
                    "dockerfile_name": "unitysetup",
                    "download_url": "https://beta.unity3d.com/download/9d528d026557/UnitySetup-2019.2.21f1",
                    "platforms": {"facebook": {"components": "Facebook-Games"}},
                    "release_notes": "https://unity3d.com/unity/whats-new/2019.2.21",
                    "release_url": "https://beta.unity3d.com/download/9d528d026557/public_download.html",
                    "sha1": "e1bf0167dda7897385adf7bb53a14195ffaa98e2",
                    "underscore": "2019_2_21f1",
                    "variables": {
                        "android": {
                            "ANDROID_NDK": "http://dl.google.com/android/repository/android-ndk-r16b-linux-x86_64.zip",
                            "ANDROID_SDK_BUILDTOOLS": "http://dl.google.com/android/repository/build-tools_r28-linux.zip",
                            "ANDROID_SDK_PLATFORM": "http://dl.google.com/android/repository/platform-28_r06.zip",
                            "ANDROID_SDK_PLATFORMTOOLS": "http://dl.google.com/android/repository/platform-tools_r28.0.3-linux.zip",
                            "ANDROID_SDK_SDKTOOLS": "http://dl.google.com/android/repository/sdk-tools-linux-4333796.zip",
                        }
                    },
                    "version": "2019.2.21",
                }
            }
            self.do_test_generate_unity_version_block(
                releases_source, release_key, release_index, expected_release_result
            )

        release_key = "beta"
        releases_source = "data/releases-linux-2020-02-18.json"
        release_index = 0
        with self.subTest(f"{releases_source} {release_key}[{release_index}]"):
            expected_release_result = {
                "2020.1.0a23": {
                    "build": "a23",
                    "dockerfile_name": "unitysetup",
                    "download_url": "https://beta.unity3d.com/download/607f55d6e9ce/UnitySetup-2020.1.0a23",
                    "release_notes": "https://unity3d.com/unity/whats-new/2020.1.0",
                    "release_url": "https://beta.unity3d.com/download/607f55d6e9ce/public_download.html",
                    "sha1": "03376c0669c4e48e13ab3ae9d54a0e0e07294906",
                    "underscore": "2020_1_0a23",
                    "variables": {
                        "android": {
                            "ANDROID_NDK": "http://dl.google.com/android/repository/android-ndk-r19-linux-x86_64.zip",
                            "ANDROID_SDK_BUILDTOOLS": "http://dl.google.com/android/repository/build-tools_r28-linux.zip",
                            "ANDROID_SDK_PLATFORM": "http://dl.google.com/android/repository/platform-28_r06.zip",
                            "ANDROID_SDK_PLATFORMTOOLS": "http://dl.google.com/android/repository/platform-tools_r28.0.3-linux.zip",
                            "ANDROID_SDK_SDKTOOLS": "http://dl.google.com/android/repository/sdk-tools-linux-4333796.zip",
                        }
                    },
                    "version": "2020.1.0",
                }
            }
            self.do_test_generate_unity_version_block(
                releases_source, release_key, release_index, expected_release_result
            )

    def do_test_generate_unity_version_block(
        self, releases_source, release_key, release_index, expected_release
    ):
        check_new_version = CheckNewVersion()
        with open(utils.full_path_from_relative_path(releases_source)) as f:
            json_text = f.read()
        official_release = json.loads(json_text)[release_key][release_index]
        version_block = check_new_version.generate_unity_version_configuration(
            official_release
        )
        self.assertEqual(expected_release, version_block)

    @requests_mock.mock()
    def test_download_file(self, mocked_request):
        url = "https://example.com"
        mocked_request.get("https://example.com", text="example")
        file_name = "temp_file.txt"
        CheckNewVersion.download_file(url, file_name)
        with open(file_name, "r") as f:
            downloaded_file_content = f.read()
        self.assertEqual("example", downloaded_file_content)
        os.remove(file_name)

    @requests_mock.mock()
    def test_get_sha1_from_download_url(self, mocked_request):
        check_new_version = CheckNewVersion()
        download_url = "https://example.com"
        mocked_request.get(download_url, text="example")
        sha1 = check_new_version.get_sha1_from_download_url(download_url)
        msg = "Downloaded UnitySetup should be removed after verifying the sha1 to keep repository clean"
        self.assertFalse(os.path.exists("UnitySetup"), msg=msg)
        expected_sha1 = "c3499c2729730a7f807efb8676a92dcb6f8a3f8f"
        self.assertEqual(expected_sha1, sha1)

    def test_sha1(self):
        file_name = utils.full_path_from_relative_path(
            "data/releases-linux-2019-05-30.json"
        )
        sha1 = CheckNewVersion.sha1(file_name)
        expected_sha1 = "efc51a5c7db46ec664b3671ce3f918297179c254"
        self.assertEqual(expected_sha1, sha1)

    def test_get_hash_from_download_url(self):
        url = "https://beta.unity3d.com/download/9d528d026557/UnitySetup-2019.2.21f1"
        expected_result = "9d528d026557"
        self.do_test_get_hash_from_download_url(expected_result, url)

        url = "https://download.unity3d.com/download_unity/c663def8414c/LinuxEditorInstaller/Unity.tar.xz"
        expected_result = "c663def8414c"
        self.do_test_get_hash_from_download_url(expected_result, url)

    def do_test_get_hash_from_download_url(self, expected_result, url):
        with self.subTest(f"{url} -> {expected_result}"):
            result = CheckNewVersion.get_hash_from_download_url(url)
            self.assertEqual(expected_result, result)

    def test_output(self):
        # TODO: complete this test using similar snapshot testing pattern from gitlab_ci_generator.py
        pass
