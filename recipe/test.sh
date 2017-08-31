#!/usr/bin/env bash

# --- Testing logic, should be moved out to a test script and update meta.yaml accordingly

BAZEL_OUT_DIR="./bazel_output_base"
export BAZEL_OPTS="--batch --output_base=${BAZEL_OUT_DIR}"

# Run unit tests on the pip installation
# Logic here is based off run_pip_tests.sh in the tensorflow repo
# https://github.com/tensorflow/tensorflow/blob/v1.1.0/tensorflow/tools/ci_build/builds/run_pip_tests.sh
# Note that not all tensorflow tests are run here, only python specific

# tests neeed to be moved into a sub-directory to prevent python from picking
# up the local tensorflow directory
PIP_TEST_PREFIX=bazel_pip
PIP_TEST_ROOT=$(pwd)/${PIP_TEST_PREFIX}
rm -rf ${PIP_TEST_ROOT}
mkdir -p ${PIP_TEST_ROOT}
ln -s $(pwd)/tensorflow ${PIP_TEST_ROOT}/tensorflow

# Test which are known to fail on a given platform
KNOWN_FAIL=""

PIP_TEST_FILTER_TAG="-no_pip_gpu,-no_pip"
BAZEL_FLAGS="--define=no_tensorflow_py_deps=true --test_lang_filters=py \
             --build_tests_only -k --test_tag_filters=${PIP_TEST_FILTER_TAG} \
             --test_timeout 9999999"
BAZEL_TEST_TARGETS="${PIP_TEST_PREFIX}/tensorflow/contrib/... \
    ${PIP_TEST_PREFIX}/tensorflow/python/... \
    ${PIP_TEST_PREFIX}/tensorflow/tensorboard/..."
BAZEL_PARALLEL_TEST_FLAGS="--local_test_jobs=1"
# Tests take ~3 hours to run and therefore are skipped in most builds
# These should be run at least once for each new release
LD_LIBRARY_PATH="/usr/local/nvidia/lib64:/usr/local/cuda/extras/CUPTI/lib64:${LD_LIBRARY_PATH}" bazel \
    ${BAZEL_OPTS} test ${BAZEL_FLAGS} \
    ${BAZEL_PARALLEL_TEST_FLAGS} -- ${BAZEL_TEST_TARGETS} ${KNOWN_FAIL}


# exec env - \
#    PATH=/bin:/opt/conda/bin:/opt/rh/devtoolset-2/root/usr/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/bin \
#  external/local_config_cuda/crosstool/clang/bin/crosstool_wrapper_driver_is_not_gcc -o bazel-out/host/bin/tensorflow/contrib/resampler/gen_resampler_ops_py_wrappers_cc -Lbazel-out/host/bin/_solib_local/_U@local_Uconfig_Ucuda
#_S_Scuda_Ccudart___Uexternal_Slocal_Uconfig_Ucuda_Scuda_Scuda_Slib '-Wl,-rpath,$ORIGIN/../../../_solib_local/_U@local_Uconfig_Ucuda_S_Scuda_Ccudart___Uexternal_Slocal_Uconfig_Ucuda_Scuda_Scuda_Slib' -Wl,-rpath,../local_config
#_cuda/cuda/lib64 -Wl,-rpath,../local_config_cuda/cuda/extras/CUPTI/lib64 -pthread -Wl,-no-as-needed -B/usr/bin/ -pie -Wl,-z,relro,-z,now -no-canonical-prefixes -pass-exit-codes '-Wl,--build-id=md5' '-Wl,--hash-style=gnu' -Wl,
#-S -Wl,--gc-sections -Wl,@bazel-out/host/bin/tensorflow/contrib/resampler/gen_resampler_ops_py_wrappers_cc-2.params): com.google.devtools.build.lib.shell.BadExitStatusException: Process exited with status 1.
#/usr/bin/ld: bazel-out/host/bin/tensorflow/contrib/resampler/gen_resampler_ops_py_wrappers_cc: undefined reference to symbol 'clock_gettime@@GLIBC_2.2.5'
#/usr/bin/ld: note: 'clock_gettime@@GLIBC_2.2.5' is defined in DSO /lib64/librt.so.1 so try adding it to the linker command line
#/lib64/librt.so.1: could not read symbols: Invalid operation
#collect2: error: ld returned 1 exit status
