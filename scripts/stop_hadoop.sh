#!/usr/bin/env bash
# Tắt Hadoop (dữ liệu trên HDFS vẫn được giữ lại):  bash scripts/stop_hadoop.sh
source "$(dirname "$0")/common.sh"

step "Tắt các daemon (ngược thứ tự lúc bật)"
run mapred --daemon stop historyserver
run yarn --daemon stop nodemanager
run yarn --daemon stop resourcemanager
run hdfs --daemon stop datanode
run hdfs --daemon stop namenode

step "Kiểm tra lại (chỉ còn Jps là đúng)"
run jps
