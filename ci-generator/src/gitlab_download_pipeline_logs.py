import json
import pickle
import urllib

import requests
import os
import re


class BearerAuth(requests.auth.AuthBase):
    def __init__(self, token):
        self.token = token

    def __call__(self, r):
        r.headers["authorization"] = "Bearer " + self.token
        return r


class GitlabDownloadPipelineLogs(object):
    def __init__(self):
        self.GITLAB_PRIVATE_TOKEN = os.environ.get("GITLAB_PRIVATE_TOKEN")
        self.GITLAB_BASE_URL = os.environ.get(
            "GITLAB_BASE_URL", default="https://gitlab.com/"
        )
        self.PROJECT_ID = os.environ.get("PROJECT_ID", default="gableroux/unity3d")
        self.ENCODED_PROJECT_ID = urllib.parse.quote(self.PROJECT_ID, safe='')

        self.SKIP_API_CALLS = os.environ.get("SKIP_API_CALLS", default=0) == 1

        self.GITLAB_API_MAX_PER_PAGE = 200
        self._GITLAB_API_MAX_PAGES_RANGE = range(1000)

        self.DOCKER_REGISTRY_API_URL = os.environ.get(
            "DOCKER_REGISTRY_API_URL", default="https://registry-1.docker.io/v2/"
        )
        self.DOCKER_REGISTRY_IMAGE_NAME = os.environ.get(
            "DOCKER_REGISTRY_IMAGE_NAME", default="gableroux/unity3d"
        )

    def main(self):
        if self.SKIP_API_CALLS:
            android_jobs = pickle.load(open("output/android-jobs.p", "rb"))
        else:
            print("Get android jobs")
            android_jobs = self.get_android_jobs()
            pickle.dump(android_jobs, open("output/android-jobs.p", "wb"))
        print(f"Found {len(android_jobs)} jobs")

        traces = []
        if self.SKIP_API_CALLS:
            android_jobs = pickle.load(open("output/android_jobs_with_digest.p", "rb"))
            for (dirpath, dirnames, filenames) in os.walk("output/traces/"):
                for f in filenames:
                    target = os.path.join(dirpath, f)
                    if os.path.getsize(target) > 0:
                        traces.append(pickle.load(open(target, "rb")))
        else:
            print("Fetch job logs and inject sha256 digest")
            traces = self.inject_digest_in_android_jobs(android_jobs)
            pickle.dump(android_jobs, open("output/android_jobs_with_digest.p", "wb"))

        print(f"processed {len(android_jobs)} jobs")
        for job in android_jobs:
            version = (
                job["name"]
                .replace("build-master unity_", "")
                .replace("unity_", "")
                .replace("_", ".")
            )
            job["docker_image"] = "gableroux/unity3d:" + version
            job["version"] = version

        if self.SKIP_API_CALLS:
            android_jobs = pickle.load(open("output/android_jobs_with_digest_and_latest_digests.p", "rb"))
            manifests_responses = pickle.load(open("output/manifests_responses.p", "rb"))
        else:
            manifests_responses = self.inject_latest_digest_in_android_jobs(android_jobs)
            pickle.dump(android_jobs, open("output/android_jobs_with_digest_and_latest_digests.p", "wb"))
            pickle.dump(manifests_responses, open("output/manifests_responses.p", "wb"))

        for job in android_jobs:
            job["digest_different_from_latest"] = job["digest"] != job["latest_digest"]
            if not job["digest_different_from_latest"]:
                print(job['name'])

        print("Write to csv")
        output_csv_file = "output/android-versions.csv"
        self.write_csv(android_jobs[0].keys(), android_jobs, output_csv_file)
        print('Done')

    def inject_latest_digest_in_android_jobs(self, android_jobs):
        manifests_responses = []
        for i, job in enumerate(android_jobs):
            try:
                latest_digest, response = self.get_latest_digest(job['version'], i)
                job["latest_digest"] = latest_digest
                manifests_responses.append(response)
            except Exception as e:
                print(e)
        return manifests_responses

    def get_latest_digest(self, version, i=0):
        auth_url = f"https://auth.docker.io/token?service=registry.docker.io&scope=repository:{self.PROJECT_ID}:pull,push"
        print(i, auth_url)
        auth_token_response = requests.get(auth_url)
        print(i, auth_token_response)
        token = json.loads(auth_token_response.content)["token"]
        manifest_url = f"{self.DOCKER_REGISTRY_API_URL}gableroux/unity3d/manifests/{version}"
        print(i, manifest_url)
        response = requests.get(
            manifest_url,
            headers={"PRIVATE-TOKEN": self.GITLAB_PRIVATE_TOKEN},
            auth=BearerAuth(token),
        )
        print(i, "status:", response.status_code)
        # manifest = json.loads(response.content)
        latest_digest = response.headers["Docker-Content-Digest"].replace(
            "sha256:", ""
        )
        print(i, "latest_digest:", latest_digest)
        return latest_digest, response

    def write_csv(self, csv_columns, dict_data, output_csv_file):
        import csv

        try:
            with open(output_csv_file, "w") as csvfile:
                writer = csv.DictWriter(csvfile, fieldnames=csv_columns)
                writer.writeheader()
                for data in dict_data:
                    writer.writerow(data)
        except IOError:
            print("I/O error")

    def inject_digest_in_android_jobs(self, android_jobs):
        trace_responses = []
        digest_regex = re.compile("(digest\: sha256\:)([A-Fa-f0-9]{64})")

        for i, android_job in enumerate(android_jobs):
            job_id = android_job['id']
            response, sha256 = self.get_digest_from_trace(digest_regex, job_id, i)
            try:
                android_job["digest"] = sha256
            except AttributeError:
                pass
            trace_responses.append(response)

    def get_digest_from_trace(self, digest_regex, job_id, i=0):
        # https://docs.gitlab.com/ee/api/jobs.html#get-a-log-file
        trace_url = f"{self.GITLAB_BASE_URL}/api/v4/projects/{self.ENCODED_PROJECT_ID}/jobs/{job_id}/trace"
        print(i, trace_url)
        response = requests.get(
            trace_url, headers={"PRIVATE-TOKEN": self.GITLAB_PRIVATE_TOKEN}
        )
        pickle.dump(response, open(f"output/traces/{job_id}.p", "wb"))
        print(i, "status:", response.status_code)
        current_trace = response.content
        digest_match = digest_regex.search(str(current_trace, encoding="utf-8"))
        sha256 = digest_match.group(2)
        return response, sha256

    def get_android_jobs(self):

        jobs = []
        responses = []
        android_jobs = []

        for i in self._GITLAB_API_MAX_PAGES_RANGE:
            response = self.get_job_response(i)
            pickle.dump(response, open(f"output/jobs/{i}.p", "wb"))
            print(i, "status:", response.status_code)
            if response.content == b"[]":
                print("End of pagination")
                break
            current_jobs = json.loads(response.content)
            current_android_jobs = [
                job
                for job in current_jobs
                if "android" in job["name"] and job["ref"] == "master"
            ]

            responses.append(response)
            jobs.append(current_jobs)

            android_jobs.extend(current_android_jobs)

        return android_jobs

    def get_job_response(self, page):
        # https://docs.gitlab.com/ee/api/jobs.html
        job_base_url = f"{self.GITLAB_BASE_URL}/api/v4/projects/{self.ENCODED_PROJECT_ID}/jobs?scope[]=success"
        # https://docs.gitlab.com/ee/api/#pagination
        job_url = f"{job_base_url}&per_page={self.GITLAB_API_MAX_PER_PAGE}&page={page}"
        print(page, job_url)
        response = requests.get(
            job_url, headers={"PRIVATE-TOKEN": self.GITLAB_PRIVATE_TOKEN}
        )
        return response


if __name__ == "__main__":
    GitlabDownloadPipelineLogs().main()
