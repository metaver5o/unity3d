# Script to generate the `.gitlab-ci.yml`

This is a python script that will generate the `.gitlab-ci.yml` to make it easier to build desired unity versions. For easier usage, use `docker-compose`.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Move existing versions from `unity_versions.yml` to unity_versions.old.yml`](#move-existing-versions-from-unity_versionsyml-to-unity_versionsoldyml)
- [Where to find hashes](#where-to-find-hashes)
- [How to get the sha1](#how-to-get-the-sha1)
- [How to specify different Dockerfile](#how-to-specify-different-dockerfile)
    - [For all images of a given version](#for-all-images-of-a-given-version)
    - [For specific components](#for-specific-components)
- [Android SDK, JDK and NDK details for android component](#android-sdk-jdk-and-ndk-details-for-android-component)
    - [Environment variable usage](#environment-variable-usage)
    - [Where to find ndk and sdk values](#where-to-find-ndk-and-sdk-values)
- [Example](#example)
- [Development](#development)
    - [Testing](#testing)
    - [Failing snapshot tests](#failing-snapshot-tests)
    - [Get code coverage report](#get-code-coverage-report)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## How to update the project

The is a script in the parent directory which should do everything you need to create a new branch, update the repo, fetch new versions from unity and generate the ci-file with the generator. All you need is docker-compose installed and your `git` command line correctly setup. Running the following command should do everything you need. Just read the scripts to see what's going on.

```bash
./script/update.sh
```

You can then submit a merge request and if everything looks fine, it will be merged :+1:

## Where to find hashes

There doesn't seem to be an official place for this, but one can find a lot of information in [the well maintained archlinux unity-editor AUR](https://aur.archlinux.org/cgit/aur.git/?h=unity-editor). For the latest version, you can find them at the same place where unity-hub electron application finds them: https://public-cdn.cloud.unity3d.com/hub/prod/releases-linux.json

Pro tip: use [jq](https://stedolan.github.io/jq/)

```bash
curl https://public-cdn.cloud.unity3d.com/hub/prod/releases-linux.json | jq '.'
```

## How to get the sha1

1. Download the `UnitySetup` file manually
2. Retrieve the sha1 with `sha1sum` command

example:

```bash
wget https://beta.unity3d.com/download/dc414eb9ed43/UnitySetup-2019.1.3f1 -O unity.deb
sha1sum unity.deb | awk '{print $1}'
```

## How to specify different Dockerfile

### For all images of a given version

Set something like this in `unity_versions.yml`:

```yaml
2018.4.0f1:
  dockerfile: my-version-specific.Dockerfile
  # ...
```

### For specific components

The generator script will automatically try to use the `Dockerfile` for the component so if you set `dockerfile: unitysetup.Dockerfile`, the `android` component will use `unitysetup-android.Dockerfile` if it exists, otherwise, it will fallback to `unitysetup.Dockerfile`.

## Android SDK, JDK and NDK details for android component

### Environment variable usage

* `property` > `automatically generated env var`
* `android_jdk_url` > `ANDROID_JDK` (Optional): url to download Android jdk (OpenJDK)  
* `android_ndk_url` > `ANDROID_NDK`: url to download ndk  
* `android_sdk_buildtools_url` > `ANDROID_SDK_BUILDTOOLS`: url to download buildtools  
* `android_sdk_platform_url` > `ANDROID_SDK_PLATFORM`: url to download platform  
* `android_sdk_platformtools_url` > `ANDROID_SDK_PLATFORMTOOLS`: url to download plateformtools  
* `android_sdk_sdktools_url` > `ANDROID_SDK_SDKTOOLS`: url to download sdktools

### Where to find ndk and sdk values

Values are populated by `check_new_version.py`, here are some additional details:

To get the available urls to fill env var, download the [repository file](http://dl.google.com/android/repository/repository-11.xml)  
The url will always start with `http://dl.google.com/android/repository/` and end with `sdk:url` value.  
For example, if you want use buildtools 28, the value of `ANDROID_SDK_BUILDTOOLS` will be `https://dl.google.com/android/repository/build-tools_r28-linux.zip`.  

Be attentive of the requirement made by Unity for android build, see [unity android-sdksetup manual](https://docs.unity3d.com/Manual/android-sdksetup.html).

## Example

For the version `2019.3.11f1` here are the versions used:
  
* NDK: `android-ndk-r19-linux-x86_64.zip`  
* SDK BUILDTOOLS: `build-tools_r28-linux.zip`  
* SDK PLATFORM: `platform-28_r06.zip`  
* SDK PLATFORMTOOLS: `platform-tools_r28.0.3-linux.zip`  
* SDK SDKTOOLS: `sdk-tools-linux-4333796.zip`  

`unity_versions.yml` looks like this:
  
```yaml
2019.3.11f1:
  build: f1
  dockerfile_name: unitysetup
  download_url: https://beta.unity3d.com/download/ceef2d848e70/UnitySetup-2019.3.11f1
  release_notes: https://unity3d.com/unity/whats-new/2019.3.11f1
  release_url: https://beta.unity3d.com/download/ceef2d848e70/public_download.html
  sha1: 13c9e693b13a8b05c7f29390f44fd89a412ffcc2
  underscore: 2019_3_11f1
  version: 2019.3.11
  variables:
    android:
      ANDROID_NDK: "http://dl.google.com/android/repository/android-ndk-r19-linux-x86_64.zip"
      ANDROID_SDK_BUILDTOOLS: "http://dl.google.com/android/repository/build-tools_r28-linux.zip"
      ANDROID_SDK_PLATFORM: "http://dl.google.com/android/repository/platform-28_r06.zip"
      ANDROID_SDK_PLATFORMTOOLS: "http://dl.google.com/android/repository/platform-tools_r28.0.3-linux.zip"
      ANDROID_SDK_SDKTOOLS: "http://dl.google.com/android/repository/sdk-tools-linux-4333796.zip"
```

## Development

### Testing

Tests make it easier to maintain the generator. It's only a way to get a breakpoint anywhere in the code, don't be scared ;)

```bash
docker-compose run --rm test
```

### Failing snapshot tests

If tests are failing due to updated ci template, you can generate snapshot tests using the following command:

```bash
docker-compose run --rm update-test-snapshots
```

### Get code coverage report

```bash
docker-compose run --rm test
docker-compose run --rm test-report
docker-compose run --rm test-report-html
```

Then open `htmlcov/index.html` :+1:
