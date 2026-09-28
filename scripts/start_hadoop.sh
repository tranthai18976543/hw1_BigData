#!/usr/bin/env bash
# Khởi động Hadoop trên máy này:  bash scripts/start_hadoop.sh
source "$(dirname "$0")/common.sh"

step "HDFS: NameNode (quản lý metadata) + DataNode (lưu block dữ liệu)"
run hdfs --daemon start namenode
run hdfs --daemon start datanode

step "YARN: ResourceManager (cấp phát tài nguyên) + NodeManager (chạy các task)"
run yarn --daemon start resourcemanager
run yarn --daemon start nodemanager

step "JobHistory Server (xem lại chi tiết các job đã chạy xong)"
run mapred --daemon start historyserver

step "Chờ HDFS sẵn sàng rồi tạo thư mục home /user/$USER"
run hdfs dfsadmin -safemode wait
run hdfs dfs -mkdir -p "/user/$USER"

step "Các tiến trình Java đang chạy (phải thấy đủ 5 cái + Jps)"
run jps

cat <<EOF

Giao diện web:
  HDFS (NameNode)    http://localhost:9870
  YARN (ResourceMgr) http://localhost:8088
  JobHistory         http://localhost:19888
EOF
