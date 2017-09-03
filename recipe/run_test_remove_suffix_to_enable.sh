#!/usr/bin/env bash
#
# TODO: make this work; it entails:
#   - Allow bazel to run the tests *using the conda installed package*-
#     Which probably means copying stuff in the test section of meta.yaml
#
#   - Activate more tests if needed
#
#   - Make (nearly) all tests pass. The current failures are at the bottom of
#     this file. Probably the patches in the recipe at anaconda.org will
#     fix many (for example the failing tests in the distributions package).
#     Explicitly tell which ones do not pass in KNOWN_FAIL
#
# Run unit tests on the conda installation.
# Logic here is based off run_pip_tests.sh in the tensorflow repo
#   https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/ci_build/builds/run_pip_tests.sh
# Note that not all tensorflow tests are run here, only python specific
#
# Tests take ~3 hours to run and therefore should be skipped while adapting the recipe.
# These should be run at least once for each new release
#

BAZEL_OUT_DIR="./bazel_output_base"
export BAZEL_OPTS="--batch --output_base=${BAZEL_OUT_DIR}"

# Tests neeed to be moved into a sub-directory to prevent python
# from picking up the local tensorflow directory.
PIP_TEST_PREFIX=bazel_pip
PIP_TEST_ROOT=${SRC_DIR}/${PIP_TEST_PREFIX}
rm -rf ${PIP_TEST_ROOT}
mkdir -p ${PIP_TEST_ROOT}
ln -s ${SRC_DIR}/tensorflow ${PIP_TEST_ROOT}/tensorflow

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

LD_LIBRARY_PATH="/usr/local/nvidia/lib64:/usr/local/cuda/extras/CUPTI/lib64:${LD_LIBRARY_PATH}" bazel \
    ${BAZEL_OPTS} test ${BAZEL_FLAGS} \
    ${BAZEL_PARALLEL_TEST_FLAGS} -- ${BAZEL_TEST_TARGETS} ${KNOWN_FAIL}

#
# Current failures:
#
#//bazel_pip/tensorflow/contrib/distributions:binomial_test               FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/binomial_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:chi2_test                   FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/chi2_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:geometric_test              FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/geometric_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:inverse_gamma_test          FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/inverse_gamma_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:logistic_test               FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/logistic_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:mixture_test                FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/mixture_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:mvn_diag_test               FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/mvn_diag_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:mvn_full_covariance_test    FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/mvn_full_covariance_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:mvn_tril_test               FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/mvn_tril_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:negative_binomial_test      FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/negative_binomial_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:poisson_test                FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/poisson_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:quantized_distribution_test FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/quantized_distribution_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:relaxed_bernoulli_test      FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/relaxed_bernoulli_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:relaxed_onehot_categorical_test FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/relaxed_onehot_categorical_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:sigmoid_test                FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/sigmoid_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:transformed_distribution_test FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/transformed_distribution_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:vector_student_t_test       FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/vector_student_t_test/test.log
#//bazel_pip/tensorflow/contrib/distributions:wishart_test                FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/distributions/wishart_test/test.log
#//bazel_pip/tensorflow/contrib/image:image_ops_test                      FAILED in 1 out of 2 in 8.9s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/image/image_ops_test/test.log
#//bazel_pip/tensorflow/contrib/keras:image_test                          FAILED in 1 out of 2 in 0.7s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/keras/image_test/test.log
#//bazel_pip/tensorflow/contrib/learn:kmeans_test                         FAILED in 1 out of 2 in 0.1s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/learn/kmeans_test/test.log
#//bazel_pip/tensorflow/contrib/opt:drop_stale_gradient_optimizer_test    FAILED in 1 out of 2 in 0.0s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/opt/drop_stale_gradient_optimizer_test/test.log
#//bazel_pip/tensorflow/contrib/opt:external_optimizer_test               FAILED in 1 out of 2 in 1.3s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/contrib/opt/external_optimizer_test/test.log
#//bazel_pip/tensorflow/python/debug:debugger_cli_common_test             FAILED in 1 out of 2 in 0.5s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/python/debug/debugger_cli_common_test/test.log
#//bazel_pip/tensorflow/python/kernel_tests:summary_image_op_test         FAILED in 1 out of 2 in 0.8s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/python/kernel_tests/summary_image_op_test/test.log
#//bazel_pip/tensorflow/python/kernel_tests:tensor_array_ops_test         FAILED in 3 out of 4 in 0.5s
#  Stats over 3 runs: max = 0.5s, min = 0.5s, avg = 0.5s, dev = 0.0s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/python/kernel_tests/tensor_array_ops_test/test_attempts/attempt_1.log
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/python/kernel_tests/tensor_array_ops_test/test_attempts/attempt_2.log
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/python/kernel_tests/tensor_array_ops_test/test.log
#//bazel_pip/tensorflow/python:localhost_cluster_performance_test         FAILED in 1 out of 2 in 0.5s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/python/localhost_cluster_performance_test/test.log
#//bazel_pip/tensorflow/python:sync_replicas_optimizer_test               FAILED in 1 out of 2 in 0.6s
#  /feedstock_root/build_artefacts/tensorflow_1504138937161/work/tensorflow-1.3.0/bazel_output_base/execroot/tensorflow-1.3.0/bazel-out/local_linux-opt/testlogs/bazel_pip/tensorflow/python/sync_replicas_optimizer_test/test.log
#
#Executed 689 out of 689 tests: 661 tests pass and 28 fail locally.
#There were tests whose specified size is too big. Use the --test_verbose_timeout_warnings command line option to see which ones these are.
#