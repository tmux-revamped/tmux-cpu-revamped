#!/bin/sh

cpu_revamped_dir=$(cd "$(dirname "$0")" && pwd)
"${cpu_revamped_dir}/bin/cpu-revamped" apply
