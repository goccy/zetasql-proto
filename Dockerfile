FROM ubuntu:18.04 as build

RUN apt-get update && apt-get -qq install -y default-jre default-jdk

RUN apt-get update && apt-get -qq install curl tar build-essential wget        \
    python python3 zip unzip

ENV BAZEL_VERSION=6.2.0

RUN mkdir -p bazel                                                          && \
    cd bazel                                                                && \
    wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip &&\
    unzip bazel-${BAZEL_VERSION}-dist.zip                                              && \
    rm -rf bazel-${BAZEL_VERSION}-dist.zip

ENV PATH=$PATH:/usr/bin:/usr/local/bin
ENV EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk"
RUN cd bazel && bash ./compile.sh
RUN cp /bazel/output/bazel  /usr/local/bin

RUN apt-get update && DEBIAN_FRONTEND="noninteractive"                         \
    TZ="America/Los_Angeles" apt-get install -y tzdata

RUN apt-get -qq install -y software-properties-common
RUN add-apt-repository ppa:ubuntu-toolchain-r/test                          && \
    apt-get -qq update                                                      && \
    apt-get -qq install -y gcc-11 g++-11 make rename  git                   && \
    apt-get -qq install -y ca-certificates libgnutls30                      && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 90          \
                        --slave   /usr/bin/g++ g++ /usr/bin/g++-11          && \
    update-alternatives --set gcc /usr/bin/gcc-11

WORKDIR /work

RUN git clone https://github.com/google/zetasql .zetasql

ENV BAZEL_ARGS="--config=g++"
ENV CC=/usr/bin/gcc
ENV CXX=/usr/bin/g++

RUN cd ./.zetasql && bazel build ${BAZEL_ARGS} '//zetasql/parser:gen_protos'
RUN cp $(find $(readlink ./.zetasql/bazel-out) -name 'parse_tree.proto') .
