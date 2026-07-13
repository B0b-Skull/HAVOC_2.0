#!/usr/bin/env bash
# save as: scripts/test-gcc-compatibility.sh
# Make executable: chmod +x scripts/test-gcc-compatibility.sh
# Test against all installed compilers or specific compilers: ./scripts/test-gcc-compatibility.sh 10 11 12 13 14 15 16
# Parrallel compilations: PARALLEL_JOBS=8 ./scripts/test-gcc-compatibility.sh 11 12 13 14 15 16
#
#



set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLIENT_DIR="${REPO_ROOT}/client"
RESULTS_DIR="${REPO_ROOT}/gcc-compatibility-results"
SUMMARY_FILE="${RESULTS_DIR}/summary.csv"

BUILD_TYPE="${BUILD_TYPE:-Release}"
PARALLEL_JOBS="${PARALLEL_JOBS:-$(nproc 2>/dev/null || echo 2)}"
PYTHON_EXECUTABLE="${PYTHON_EXECUTABLE:-$(command -v python3 || true)}"

# Set to 1 to stop after the first compiler failure.
FAIL_FAST="${FAIL_FAST:-0}"

# Optionally specify versions on the command line:
# ./scripts/test-gcc-compatibility.sh 10 11 12 13 14 15 16
REQUESTED_VERSIONS=("$@")

mkdir -p "${RESULTS_DIR}"

printf '%s\n' \
    "requested_version,actual_gcc_version,actual_gxx_version,configure,build,executable,status,log" \
    > "${SUMMARY_FILE}"

log()
{
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

find_compiler_versions()
{
    local compiler
    local version

    for compiler in $(compgen -c gcc- 2>/dev/null | sort -u); do
        if [[ "${compiler}" =~ ^gcc-([0-9]+)$ ]]; then
            version="${BASH_REMATCH[1]}"

            if command -v "g++-${version}" >/dev/null 2>&1; then
                printf '%s\n' "${version}"
            fi
        fi
    done
}

find_havoc_executable()
{
    local build_dir="$1"
    local candidate

    candidates=(
        "${build_dir}/Havoc"
        "${CLIENT_DIR}/Havoc"
        "${CLIENT_DIR}/Bin/Havoc"
        "${CLIENT_DIR}/Bin/HavocClient"
    )

    for candidate in "${candidates[@]}"; do
        if [[ -f "${candidate}" && -x "${candidate}" ]]; then
            printf '%s\n' "${candidate}"
            return 0
        fi
    done

    # Fallback: find a recently built executable named Havoc.
    find "${build_dir}" "${CLIENT_DIR}/Bin" \
        -maxdepth 3 \
        -type f \
        -name 'Havoc' \
        -perm -111 \
        2>/dev/null \
        | head -n 1
}

test_compiler()
{
    local version="$1"
    local cc="gcc-${version}"
    local cxx="g++-${version}"

    local build_dir="${RESULTS_DIR}/build-gcc-${version}"
    local log_file="${RESULTS_DIR}/gcc-${version}.log"

    local gcc_version="unavailable"
    local gxx_version="unavailable"
    local configure_result="FAIL"
    local build_result="NOT_RUN"
    local executable_result="NOT_FOUND"
    local overall_status="FAIL"
    local executable_path=""

    log "Testing GCC ${version}"

    if ! command -v "${cc}" >/dev/null 2>&1; then
        log "Skipping GCC ${version}: ${cc} was not found"

        printf '%s\n' \
            "${version},unavailable,unavailable,NOT_RUN,NOT_RUN,NOT_RUN,SKIPPED,${log_file}" \
            >> "${SUMMARY_FILE}"

        return 0
    fi

    if ! command -v "${cxx}" >/dev/null 2>&1; then
        log "Skipping GCC ${version}: ${cxx} was not found"

        printf '%s\n' \
            "${version},unavailable,unavailable,NOT_RUN,NOT_RUN,NOT_RUN,SKIPPED,${log_file}" \
            >> "${SUMMARY_FILE}"

        return 0
    fi

    gcc_version="$("${cc}" -dumpfullversion -dumpversion 2>/dev/null || true)"
    gxx_version="$("${cxx}" -dumpfullversion -dumpversion 2>/dev/null || true)"

    rm -rf "${build_dir}"
    mkdir -p "${build_dir}"

    {
        echo "============================================================"
        echo "HAVOC GCC compatibility test"
        echo "Requested GCC version: ${version}"
        echo "C compiler: $(command -v "${cc}")"
        echo "C++ compiler: $(command -v "${cxx}")"
        echo "GCC version: ${gcc_version}"
        echo "G++ version: ${gxx_version}"
        echo "CMake version: $(cmake --version | head -n 1)"
        echo "Python: ${PYTHON_EXECUTABLE:-not found}"
        echo "Build directory: ${build_dir}"
        echo "Date: $(date --iso-8601=seconds)"
        echo "============================================================"
        echo
    } > "${log_file}"

    if [[ -z "${PYTHON_EXECUTABLE}" ]]; then
        echo "ERROR: python3 was not found." >> "${log_file}"

        printf '%s\n' \
            "${version},${gcc_version},${gxx_version},FAIL,NOT_RUN,NOT_RUN,FAIL,${log_file}" \
            >> "${SUMMARY_FILE}"

        return 1
    fi

    log "Configuring with ${cc} and ${cxx}"

    if CC="${cc}" CXX="${cxx}" cmake \
        -S "${CLIENT_DIR}" \
        -B "${build_dir}" \
        -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
        -DCMAKE_C_COMPILER="$(command -v "${cc}")" \
        -DCMAKE_CXX_COMPILER="$(command -v "${cxx}")" \
        -DPython3_EXECUTABLE="${PYTHON_EXECUTABLE}" \
        >> "${log_file}" 2>&1
    then
        configure_result="PASS"
    else
        log "GCC ${version}: CMake configuration failed"

        printf '%s\n' \
            "${version},${gcc_version},${gxx_version},FAIL,NOT_RUN,NOT_RUN,FAIL,${log_file}" \
            >> "${SUMMARY_FILE}"

        return 1
    fi

    {
        echo
        echo "CMake-selected compilers:"
        grep -E \
            '^CMAKE_(C|CXX)_COMPILER(:FILEPATH)?=' \
            "${build_dir}/CMakeCache.txt" \
            || true
        echo
    } >> "${log_file}"

    log "Building with GCC ${version}"

    if cmake \
        --build "${build_dir}" \
        --parallel "${PARALLEL_JOBS}" \
        >> "${log_file}" 2>&1
    then
        build_result="PASS"
    else
        build_result="FAIL"

        log "GCC ${version}: build failed"

        printf '%s\n' \
            "${version},${gcc_version},${gxx_version},${configure_result},FAIL,NOT_FOUND,FAIL,${log_file}" \
            >> "${SUMMARY_FILE}"

        return 1
    fi

    executable_path="$(find_havoc_executable "${build_dir}" || true)"

    if [[ -n "${executable_path}" ]]; then
        executable_result="FOUND"
        overall_status="PASS"

        {
            echo
            echo "Generated executable:"
            echo "${executable_path}"
            file "${executable_path}" || true
        } >> "${log_file}"
    else
        executable_result="NOT_FOUND"
        overall_status="FAIL"
    fi

    printf '%s\n' \
        "${version},${gcc_version},${gxx_version},${configure_result},${build_result},${executable_result},${overall_status},${log_file}" \
        >> "${SUMMARY_FILE}"

    if [[ "${overall_status}" == "PASS" ]]; then
        log "GCC ${version}: PASS"
        return 0
    fi

    log "GCC ${version}: build completed, but no executable was found"
    return 1
}

main()
{
    local versions=()
    local version
    local failures=0

    if [[ ! -d "${CLIENT_DIR}" ]]; then
        echo "ERROR: HAVOC client directory not found: ${CLIENT_DIR}" >&2
        exit 1
    fi

    if ! command -v cmake >/dev/null 2>&1; then
        echo "ERROR: cmake is not installed." >&2
        exit 1
    fi

    if [[ "${#REQUESTED_VERSIONS[@]}" -gt 0 ]]; then
        versions=("${REQUESTED_VERSIONS[@]}")
    else
        mapfile -t versions < <(find_compiler_versions)
    fi

    if [[ "${#versions[@]}" -eq 0 ]]; then
        echo "No versioned GCC/G++ compiler pairs were found."
        echo
        echo "Install compilers such as:"
        echo "  gcc-11 g++-11"
        echo "  gcc-12 g++-12"
        echo "  gcc-13 g++-13"
        exit 1
    fi

    log "Versions selected: ${versions[*]}"
    log "Results directory: ${RESULTS_DIR}"

    for version in "${versions[@]}"; do
        if ! [[ "${version}" =~ ^[0-9]+$ ]]; then
            log "Ignoring invalid compiler version: ${version}"
            continue
        fi

        if ! test_compiler "${version}"; then
            failures=$((failures + 1))

            if [[ "${FAIL_FAST}" == "1" ]]; then
                break
            fi
        fi
    done

    echo
    echo "Compatibility results:"
    column -s, -t "${SUMMARY_FILE}" 2>/dev/null || cat "${SUMMARY_FILE}"
    echo
    echo "Detailed logs:"
    echo "  ${RESULTS_DIR}"
    echo

    if [[ "${failures}" -gt 0 ]]; then
        log "${failures} compiler test(s) failed"
        exit 1
    fi

    log "All tested compiler versions passed"
}

main