ARG BASE_IMAGE
FROM $BASE_IMAGE

RUN apt-get update -qq \
    && apt-get install -qq -y --no-install-recommends \
        clang \
        llvm-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
