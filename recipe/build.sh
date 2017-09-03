#!/bin/bash
#
# Compiles tensorflow from source.
#  https://www.tensorflow.org/install/install_sources
#
# This recipe is heavily inspired on jjhelmus work (early recipes & conda-forge PRs &
# jjhelmus / kalefranz tensorflow-gpu package in anaconda defaults)
#
# Goals:
#  - Be as conda / conda-forge friendly as possible
#  - Optimized build
#    * With SSEs, AVXs, FMAs
#    * With MKL (hopefully, against defaults MKL)
#    * With XLA
#
# It turns out this is quite futile as, in our tests, we do not run much faster than if
# we would just repackage the official universal tensorflow wheel (and it is hard to compile
# in Centos 6). The difference could be in the ability to access XLA, but at the moment
# our models are not well ingested by the jitter.
#
# For an overview of changes needed to compile on centos 6, see:
#   https://github.com/tensorflow/tensorflow/issues/110
#   https://github.com/tensorflow/tensorflow/issues/1171
#   https://github.com/tensorflow/tensorflow/issues/8529
#   https://github.com/tensorflow/tensorflow/pull/10717
#   https://gist.github.com/rasmi/e56e46ab242d1c72cca0bc0975eb8abf
#   Bruder message here: https://groups.google.com/a/tensorflow.org/forum/?hl=en#!topic/discuss/VnpcZMToQ4A
#   This does not work: --linkopt='-lrt -lm' \
#
# All this is too complicated and makes for hard job to update the recipes.
# Probably it would be wiser to give up the centos way and start building in an Ubuntu image
# that is officially supported by tensorflow.
#
# The official docker-devel image is an useful example:
#   https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/docker/Dockerfile.devel-gpu
#
# More on Jemalloc & Tensorflow & Centos 6
# ========================================
#
# Installing TF from sources: https://www.tensorflow.org/install/install_sources
# TF jemalloc bazel BUILD: https://github.com/tensorflow/tensorflow/blob/master/third_party/jemalloc.BUILD
# Jemalloc in tensorflow has a slight advantage in internal tests: https://github.com/tensorflow/tensorflow/issues/6869
# Jemalloc and transparent huge pages: https://github.com/jemalloc/jemalloc/issues/243
# TCMalloc might be a better option for convnets and TF: https://github.com/tensorflow/tensorflow/issues/3009
# Optimized TF running with jemalloc / tcmalloc using a lot of memory (and supertrick from Yaroslav): https://github.com/tensorflow/tensorflow/issues/9742
# Building TF with jemalloc on old kernels will fail: https://github.com/tensorflow/tensorflow/issues/7268 https://blog.abysm.org/2016/06/building-tensorflow-centos-6/
# Getting started with jemalloc (LD_PRELOAD trick): https://github.com/jemalloc/jemalloc/wiki/Getting-Started
# Conda-forge jemalloc recipe (from wesm, version 5 is tagged as broken): https://github.com/conda-forge/jemalloc-feedstock
#
# Newer Conda Core Tools
# ======================
#
# It is unfortunate we cannot yet use all these, it is interesting to see what the landscape will
# look like in 3 months time.
#
# Package better with conda-build 3: https://www.anaconda.com/blog/developer-blog/package-better-with-conda-build-3/
# Variants documentation: https://conda.io/docs/building/variants.html
# Conda Version 4.4 announcement: https://groups.google.com/a/continuum.io/forum/#!topic/conda/VC32lgaTMpw
#

set -ex

export CUDA_VERSION="8.0"
export CUDNN_VERSION="6.0"

export PYTHON_BIN_PATH=${PYTHON}
export PYTHON_LIB_PATH=${SP_DIR}

# --- GCC options. See:
#  https://gcc.gnu.org/onlinedocs/gcc-4.7.4/gcc/i386-and-x86-64-Options.html#i386-and-x86-64-Options
export CC_OPT_FLAGS="-march=core-avx-i -mavx2 -mfma"

# --- Tensorflow options

# Enable jemalloc (needs the patch for compilation on old glibc)
# Should advice to use a newer version using LD_PRELOAD at runtime (add post installation message)
export TF_NEED_JEMALLOC=1

# Things we don't need
export TF_NEED_GCP=0
export TF_NEED_HDFS=0
export TF_NEED_OPENCL=0
export TF_NEED_VERBS=0

# Enable XLA
export TF_ENABLE_XLA=1

# CUDA & CUDNN. Good intro & doc here:
#   https://github.com/tensorflow/tensorflow/blob/master/third_party/gpus/cuda_configure.bzl
export TF_NEED_CUDA=1
export TF_CUDA_VERSION=${CUDA_VERSION}
export TF_CUDNN_VERSION=${CUDNN_VERSION:0:1}
export TF_CUDA_CLANG=0
# Additional compute capabilities can be added if desired but these increase
# the build time and size of the package.
# Mapping hardware to compute capabilities:
#   https://developer.nvidia.com/cuda-gpus
export TF_CUDA_COMPUTE_CAPABILITIES="5.2,6.1"
export GCC_HOST_COMPILER_PATH="/opt/rh/devtoolset-2/root/usr/bin/gcc"
export CUDA_TOOLKIT_PATH="/usr/local/cuda"
export CUDNN_INSTALL_PATH="${CUDA_TOOLKIT_PATH}"

# MKL - instruct to download it (see configure)
export TF_NEED_MKL=1
export TF_DOWNLOAD_MKL=1
# If going for defaults or intel channel packages...
# Can be either mkl-dnn (comes with the gorilla in the form of "intel feature") or full mkl (mkl-include)
# export TF_DOWNLOAD_MKL=0
# export MKL_INSTALL_PATH=${PREFIX}

# configure the build
./configure

# build using bazel
BAZEL_OUT_DIR="./bazel_output_base"
mkdir -p ${BAZEL_OUT_DIR}
export BAZEL_OPTS="--batch --output_base=${BAZEL_OUT_DIR}"
bazel ${BAZEL_OPTS} build \
    --config=opt \
    --config=cuda \
    --color=yes \
    --curses=no \
    --logging=6 \
    --subcommands \
    --verbose_failures \
    //tensorflow/tools/pip_package:build_pip_package

# build a whl file, install it using pip
mkdir -p ${SRC_DIR}/tensorflow_pkg
bazel-bin/tensorflow/tools/pip_package/build_pip_package ${SRC_DIR}/tensorflow_pkg
pip install --no-deps ${SRC_DIR}/tensorflow_pkg/*.whl
