#!/usr/bin/env bash

#------------------------------------------------------------------------------
# Downloads and configures external projects used for benchmarking by external-run.sh.
#
# By default the download location is set to a subdirectory of the script directory.
# A different directory can be provided via the BENCHMARK_DIR variable.
#
# Dependencies: foundry, git.
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
BENCHMARK_DIR="${BENCHMARK_DIR:-${script_dir}/projects}"

mkdir -p "$BENCHMARK_DIR"
cd "$BENCHMARK_DIR"

if [[ ! -e openzeppelin/ ]]; then
    git clone \
        https://github.com/OpenZeppelin/openzeppelin-contracts \
        openzeppelin/ \
        --branch v5.0.2 \
        --depth=1
    pushd openzeppelin/
    forge install
    popd
else
    echo "Skipped openzeppelin/. Already exists."
fi

if [[ ! -e uniswap-v4/ ]]; then
    git clone https://github.com/Uniswap/v4-core uniswap-v4/
    pushd uniswap-v4/
    git checkout d0700ceb251afa48df8cc26d593fe04ee5e6b775 # branch main as of 2024-05-10
    forge install
    popd
else
    echo "Skipped uniswap-v4/. Already exists."
fi
