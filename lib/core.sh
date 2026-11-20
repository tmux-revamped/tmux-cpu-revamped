#!/bin/sh
# shellcheck disable=SC2034

[ -n "${CPU_REVAMPED_CORE_LOADED:-}" ] && return 0
CPU_REVAMPED_CORE_LOADED=1

readonly CPU_REVAMPED_VERSION="3.1.0"
