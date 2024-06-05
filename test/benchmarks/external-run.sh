#!/usr/bin/env bash

#------------------------------------------------------------------------------
# Benchmarks a solc binary by compiling several external projects, with and without IR.
#
# The script expects each project to be already downloaded and set up by external-setup.sh.
# A different directory can be provided via the BENCHMARK_DIR variable.
#
# The script will by default attempt to use a solc from the default build directory,
# relative to the script directory. To use a different binary you can provide a different
# location of the build directory (via SOLIDITY_BUILD_DIR variable) or simply specify
# the full path to the binary as the script argument.
#
# Dependencies: foundry, time.
# ------------------------------------------------------------------------------
# This file is part of solidity.
#
# solidity is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# solidity is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with solidity.  If not, see <http://www.gnu.org/licenses/>
#
# (c) 2024 solidity contributors.
#------------------------------------------------------------------------------

set -euo pipefail

script_dir="$(dirname "$0")"
repo_root=$(cd "${script_dir}/../../" && pwd)
BENCHMARK_DIR="${BENCHMARK_DIR:-${script_dir}/projects}"
SOLIDITY_BUILD_DIR=${SOLIDITY_BUILD_DIR:-${repo_root}/build}

# shellcheck source=scripts/common.sh
source "${repo_root}/scripts/common.sh"
# shellcheck source=scripts/common_cmdline.sh
source "${repo_root}/scripts/common_cmdline.sh"

(( $# <= 1 )) || fail "Too many arguments. Usage: external-run.sh [<solc-path>]"

solc="${1:-${SOLIDITY_BUILD_DIR}/solc/solc}"
command_available "$solc" --version

function bytecode_size {
    local bytecode_chars
    bytecode_chars=$(stripCLIDecorations | stripEmptyLines | wc --chars)
    echo $(( bytecode_chars / 2 ))
}

function benchmark_project {
    local pipeline="$1"
    local project="$2"

    cd "$project"
    local foundry_command=(forge build --use "$solc" --optimize --offline --no-cache)
    [[ $pipeline == via-ir ]] && foundry_command+=(--via-ir)
    local time_file="../time-and-status-${project}-${pipeline}.txt"

    # NOTE: The pipeline may fail with "Stack too deep" in some cases. That's fine.
    # We note the exit code and will later show full output.
    "$time_bin_path" \
        --output "$time_file" \
        --quiet \
        --format '%e s |         %x' \
            "${foundry_command[@]}" \
            > /dev/null \
            2>> "../benchmark-warn-err.txt" || true

    printf '| %-20s | %s   | %20s |\n' \
        "$project" \
        "$pipeline" \
        "$(cat "$time_file")"
    cd ..
}

benchmarks=(
    openzeppelin
    uniswap-v4
)
time_bin_path=$(type -P time)

mkdir -p "$BENCHMARK_DIR"
cd "$BENCHMARK_DIR"
: > "benchmark-warn-err.txt"

echo "| Project              | Pipeline | Time     | Exit code |"
echo "|----------------------|----------|---------:|----------:|"

for project in "${benchmarks[@]}"
do
    benchmark_project legacy "$project"
    benchmark_project via-ir "$project"
done

if [[ -s benchmark-warn-err.txt ]]; then
    echo
    echo "======================================================="
    echo "Warnings and errors generated during run:"
    echo "======================================================="
    cat benchmark-warn-err.txt
fi
