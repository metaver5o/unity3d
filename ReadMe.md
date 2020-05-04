# Unity3d docker image

[![pipeline status](https://gitlab.com/gableroux/unity3d/badges/master/pipeline.svg)](https://gitlab.com/gableroux/unity3d/commits/master) [![Docker Stars](https://img.shields.io/docker/stars/gableroux/unity3d.svg)](https://hub.docker.com/r/gableroux/unity3d/) [![Docker Pulls](https://img.shields.io/docker/pulls/gableroux/unity3d.svg)](https://hub.docker.com/r/gableroux/unity3d/) [![Docker Automated build](https://img.shields.io/docker/automated/gableroux/unity3d.svg)](https://hub.docker.com/r/gableroux/unity3d/) [![Image](https://images.microbadger.com/badges/image/gableroux/unity3d.svg)](https://microbadger.com/images/gableroux/unity3d) [![Version](https://images.microbadger.com/badges/version/gableroux/unity3d.svg)](https://microbadger.com/images/gableroux/unity3d)

This project builds docker images for all unity versions and their components. It contains a script that generates a `.gitlab-ci.yml` that is used to build and publish all of the images. All supported versions can be found in [`ci-generator/unity_versions.yml`](ci-generator/unity_versions.yml) (latest built images) and [`ci-generator/unity_versions.old.yml`](ci-generator/unity_versions.old.yml) (already built images).

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Things to consider](#things-to-consider)
- [Usage](#usage)
    - [Build the image](#build-the-image)
    - [Run the image](#run-the-image)
- [CI](#ci)
    - [Environment variables](#environment-variables)
        - [Docker](#docker)
        - [Android](#android)
    - [Personal gitlab-runner](#personal-gitlab-runner)
- [FAQ](#faq)
    - [How it all started?](#how-it-all-started)
    - [My version is missing, what can I do?](#my-version-is-missing-what-can-i-do)
    - [How are these images published to docker hub?](#how-are-these-images-published-to-docker-hub)
    - [What is `ci-generator/unity_versions.yml`?](#what-is-ci-generatorunity_versionsyml)
    - [What is `ci-generator/unity_versions.old.yml`?](#what-is-ci-generatorunity_versionsoldyml)
    - [How to build your own images](#how-to-build-your-own-images)
    - [How and where to run `docker-compose` commands](#how-and-where-to-run-docker-compose-commands)
    - [Do I need to build the docker images myself?](#do-i-need-to-build-the-docker-images-myself)
    - [How do I build and publish my own images?](#how-do-i-build-and-publish-my-own-images)
    - [How do I use these docker images?](#how-do-i-use-these-docker-images)
    - [How and where do I find the right docker image?](#how-and-where-do-i-find-the-right-docker-image)
    - [How do I find the unity version of my unity project?](#how-do-i-find-the-unity-version-of-my-unity-project)
    - [How do I know if the version I need is published or not?](#how-do-i-know-if-the-version-i-need-is-published-or-not)
- [Shameless plug](#shameless-plug)
- [Want to chat?](#want-to-chat)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Things to consider

These docker images run in a shell so you don't have access to Unity's UI. This docker image is intended to run unity commands with the **command line**. You can use it for running **tests** and **creating builds**.

## Usage

This docker image is intended to be used with a CI. An example project using unity3d in a docker image can be found at **[gableroux/unity3d-gitlab-ci-example](https://gitlab.com/gableroux/unity3d-gitlab-ci-example)**. Go there and follow its instructions if you'd like to use this image in your project.

### Build the image

Images are built automatically by the CI based on `.gitlab-ci.yml` content that is generated by **[./ci-generator](./ci-generator)**. If you'd like to build the images by yourself, you can do something like this:

```bash
docker build -t gableroux/unity3d:latest ./docker/ -f ./docker/unitysetup.Dockerfile
```

But at this point, you should fork the project, generate the the `.gitlab-ci.yml` and let gitlab build the images for you. By default, the images will be published to your fork's registry.

### Run the image

```bash
docker run -it --rm \
  -v "$(pwd):/root/project" \
  gableroux/unity3d:latest \
  xvfb-run --auto-servernum --server-args='-screen 0 640x480x24' \
  /opt/Unity/Editor/Unity -projectPath /root/project
```

## CI

### Environment variables

#### Docker

If you would like to push the docker image to your own docker registry, you need to set the following variables:   
`CI_REGISTRY_USER`  
`CI_REGISTRY_PASSWORD`  
`CI_REGISTRY`  
Mark those variables as Masked.

If you don't set it, the image will be present on the gitlab Packages -> Container registry

#### Android

See [ci-generator/ReadMe.md](./ci-generator) about Android env var.

### Personal gitlab-runner

You need to install [Docker](https://www.docker.com/get-started).  
You need to set 4Go for memory. [Source](https://stackoverflow.com/a/47027943)  
Docker -> preference -> Resources -> Memory -> 4.00GB.  

After adding your [gitlab-runner](https://docs.gitlab.com/runner/).  
In the config.toml, you need to set privileged to true and add "/certs/client" to the volumes array.  
[Source privileged](https://gitlab.com/gitlab-org/gitlab-runner/issues/1544#note_13439656) - [Source volumes](https://gitlab.com/gitlab-org/gitlab-runner/issues/4501)
See below:

```yaml
[[runners]]
  name = "xxxxxxxxxxxxxxxxxxxxx"
  url = "https://gitlab.com/"
  token = "xxxxxxxxxxxxxxxxxxxxx"
  executor = "docker"
  [runners.custom_build_dir]
  [runners.docker]
    tls_verify = false
    image = "xxxxxxxxxxxxxxxxxxxxx"
    privileged = true    #<-------- here
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/certs/client", "/cache"] #<-------- here
    shm_size = 0
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
```

## FAQ

### How it all started?

I wanted to build unity projects in the cloud and existing solutions were not exciting so I fixed that. Initial docker image was first based on [GitLab CI with Unity3D in Docker](https://www.projects.science.uu.nl/DGKVj16/blog/gitlab-ci-with-unity3d-in-docker/) but changed a lot since then, thanks to contributors!

### My version is missing, what can I do?

Have a look at the issues or merge requests first, then follow instructions in [ci-generator](./ci-generator).

### How are these images published to docker hub?

Refer to this [QA](https://stackoverflow.com/questions/45517733/how-to-publish-docker-images-to-docker-hub-from-gitlab-ci). tldr; I only updated a few environment variables in gitlab-ci settings, this is optional.

### What is `ci-generator/unity_versions.yml`?

That file can be empty because I don't always want to trigger the builds when updating the project. This is more of a technical detail. What you need to know is `ci-generator/unity_versions.yml` is where you place the required information to build one or multiple unity versions when working with this repository.

### What is `ci-generator/unity_versions.old.yml`?

In the case of this repository, the [`ci-generator/unity_versions.old.yml` (notice the `.old`)](https://gitlab.com/gableroux/unity3d/blob/f9bef9e4/ci-generator/unity_versions.old.yml) contains all of the images built to this date. Techincally, the information is also in git history, but it's more convenient to have the whole list in a file for quick reference.

_Note: the link above is freezed as this may change in the future_  
Refer to the following link for its latest version:
[`ci-generator/unity_versions.yml`](https://gitlab.com/gableroux/unity3d/blob/master/ci-generator/unity_versions.old.yml)

### How to build your own images

For example, if you'd like to build your own images for the `2019.2.5f1` unity editor, you'd have to put the following content inside the `unity_versions.yml` file:

```yaml
2019.2.5f1:
  build: f1
  dockerfile_name: unitysetup
  download_url: https://beta.unity3d.com/download/9dace1eed4cc/UnitySetup-2019.2.5f1
  release_notes: https://unity3d.com/unity/whats-new/2019.2.5f1
  release_url: https://beta.unity3d.com/download/9dace1eed4cc/public_download.html
  sha1: 56e22a22e102d325220ee313f68bd4f7ffab70ec
  underscore: 2019_2_5f1
  version: 2019.2.5
```

Then run the commands explained in [the `ci-generator/readme.md`](https://gitlab.com/gableroux/unity3d/tree/f9bef9e4/ci-generator#script-to-generate-the-gitlab-ciyml)

### How and where to run `docker-compose` commands

This is done on your own computer once you've cloned the project. You will need to have [Docker installed on your system](https://docs.docker.com/install/). If you're new to docker, I recommend yo do the [Docker getting started](https://docs.docker.com/machine/get-started/) first.

Concerning the commands, you first need to clone this repository, then you open a shell in the `ci-generator` folder and run the `docker-compose` commands.

### Do I need to build the docker images myself?

It's good practice to build your own images for a security point of view _(I guess, unless you have 100% trust in me)_. But **it is not required** to build your own Unity docker images as **these images [are already published on Docker hub](https://hub.docker.com/r/gableroux/unity3d)**. So you can simply pull the desired ones directly on your system or on CI runners such as the ones from gitlab-ci, travis, circleci, etc.

### How do I build and publish my own images?

If you don't want to use the ones already published, or would like to customize the content of your images, follow along:

1. Clone the project
2. Follow instructions in the [the `ci-generator/readme.md`](https://gitlab.com/gableroux/unity3d/tree/f9bef9e4/ci-generator#script-to-generate-the-gitlab-ciyml)

Images will be published to your project's gitlab registry and if you fork the project as private, your registry can also remain private. But that's totally optional, you can use the ones I published.

### How do I use these docker images?

[As mentioned in the ReadMe's Usage section](https://gitlab.com/gableroux/unity3d/blob/947c82cf/ReadMe.md#usage):

> This docker image is intended to be used with a CI. An example project using unity3d in a docker image can be found at **[gableroux/unity3d-gitlab-ci-example](https://gitlab.com/gableroux/unity3d-gitlab-ci-example)**. Go there and follow its instructions if you'd like to use this image in your project.

### How and where do I find the right docker image?

Images from [gitlab.com/gableroux/unity3d git repository](https://gitlab.com/gableroux/unity3d/) are [published on Docker hub](https://hub.docker.com/r/gableroux/unity3d). You should be able to use the unity version of your unity project.

Images have the following tags pattern:

* `gableroux/unity3d:<unity_version>` contains the main unity component and is able to build for `windows`, `linux`, `macos` and `webgl`
* `gableroux/unity3d:<unity_version>-<component>` where `<component>` is usually one of `windows`, `mac`, `ios`, `android`, `webgl`, `facebook`.

There may also sometimes be images published with the following patterns:

* `gableroux/unity3d:<unity_version>-<branch_name>`
* `gableroux/unity3d:<unity_version>-<component>-<branch_name>`

These are meant for development purpose only and should not be used as they are meant to disappear. They are temporary images which can (and will most likely) be deleted at any moment.

[Components are defined here](https://gitlab.com/gableroux/unity3d/blob/5bdeca28/ci-generator/src/gitlab_ci_generator.py#L82-91)

### How do I find the unity version of my unity project?

It should be located in `ProjectSettings/ProjectVersion.txt`. [Here's an example](https://gitlab.com/gableroux/unity3d-gitlab-ci-example/blob/fc76285d/ProjectSettings/ProjectVersion.txt).

In that case, it's `2019.1.14f1`, so you would be using the following docker image: `gableroux/unity3d:2019.1.14f1`

### How do I know if the version I need is published or not?

The quickest way is to look in [`ci-generator/unity_versions.yml`](https://gitlab.com/gableroux/unity3d/blob/master/ci-generator/unity_versions.old.yml) and [`ci-generator/unity_versions.yml`](https://gitlab.com/gableroux/unity3d/blob/master/ci-generator/unity_versions.yml).

The source of truth is the list of tags in the registry. [Docker hub has a page for tags where you can search](https://hub.docker.com/r/gableroux/unity3d/tags). The search feature now works very well, but it was not always the case in the past. For a more command line approach, you may also use the following technique:

```bash
skopeo --override-os linux inspect docker://gableroux/unity3d | jq '.RepoTags[]' -r | sort --version-sort
```

Commands required to be installed for the above command:
* [`skopeo`](https://github.com/containers/skopeo) _Work with remote images registries - retrieving information, images, signing content_
* [`jq`](https://stedolan.github.io/jq/) _a lightweight and flexible command-line JSON processor._

## Shameless plug

I made this for free as a gift to the video game community. If this tool helped you, feel free to become a patron for [Totema Studio](https://totemastudio.com) on Patreon: :beers:

[![Totema Studio Logo](./doc/totema-studio-logo-217.png)](https://patreon.com/totemastudio)

[![Become a Patron](./doc/become_a_patron_button.png)](https://www.patreon.com/bePatron?c=1073078)

## Want to chat?

Join us on our discord channel at [totema.studio/discord](https://totema.studio/discord), there's a technical channel in there mostly dedicated to this tool. :+1:

## License

[MIT](LICENSE.md) © [Gabriel Le Breton](https://gableroux.com)

