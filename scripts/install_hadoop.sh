#!/usr/bin/env bash
# Cài Hadoop ở chế độ pseudo-distributed (giả lập cụm phân tán trên 1 máy: đủ HDFS + YARN)
# vào ~/hadoop. Chỉ cần chạy MỘT lần, không cần sudo, chỉ cần có sẵn Java 8 hoặc 11.
#
#   bash scripts/install_hadoop.sh
#   TARBALL=/đường/dẫn/hadoop-3.4.3.tar.gz bash scripts/install_hadoop.sh   # nếu đã tải sẵn
set -eu
source "$(dirname "$0")/common.sh"

HADOOP_VERSION=3.4.3
MIRRORS=(
  "https://dlcdn.apache.org/hadoop/common/hadoop-$HADOOP_VERSION"
  "https://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION"
)
DATA_DIR=$HADOOP_HOME/data                     # nơi HDFS lưu dữ liệu thật trên ổ cứng

step "1. Kiểm tra Java"
run java -version
echo "JAVA_HOME=$JAVA_HOME"

step "2. Tải và giải nén Hadoop $HADOOP_VERSION vào $HADOOP_HOME"
if [[ -d $HADOOP_HOME ]]; then
  echo "Đã có $HADOOP_HOME -> bỏ qua bước này."
else
  if [[ -z ${TARBALL:-} ]]; then
    TARBALL=/tmp/hadoop-$HADOOP_VERSION.tar.gz
    for m in "${MIRRORS[@]}"; do
      if run curl -fL -o "$TARBALL" "$m/hadoop-$HADOOP_VERSION.tar.gz" &&
         curl -fsSL -o "$TARBALL.sha512" "$m/hadoop-$HADOOP_VERSION.tar.gz.sha512"; then
        break
      fi
    done
    (cd "$(dirname "$TARBALL")" && run sha512sum -c "$(basename "$TARBALL").sha512")
    DOWNLOADED=1
  fi
  run tar -xzf "$TARBALL" -C "$HOME"
  run mv "$HOME/hadoop-$HADOOP_VERSION" "$HADOOP_HOME"
  if [[ -n ${DOWNLOADED:-} ]]; then rm -f "$TARBALL" "$TARBALL.sha512"; fi   # tiết kiệm ổ đĩa
fi

step "3. Ghi các file cấu hình vào $HADOOP_CONF_DIR"

if ! grep -q "thêm bởi install_hadoop.sh" "$HADOOP_CONF_DIR/hadoop-env.sh"; then
  cat >> "$HADOOP_CONF_DIR/hadoop-env.sh" <<EOF

# --- thêm bởi install_hadoop.sh ---
export JAVA_HOME=$JAVA_HOME
export HADOOP_PID_DIR=$HADOOP_HOME/pids
EOF
fi

cat > "$HADOOP_CONF_DIR/core-site.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <!-- Địa chỉ NameNode: mọi đường dẫn kiểu /user/... đều hiểu là nằm trên HDFS này -->
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://localhost:9000</value>
  </property>
  <!-- Thư mục tạm (mặc định nằm trong /tmp, dễ bị xoá khi khởi động lại máy) -->
  <property>
    <name>hadoop.tmp.dir</name>
    <value>$DATA_DIR/tmp</value>
  </property>
</configuration>
EOF

cat > "$HADOOP_CONF_DIR/hdfs-site.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <!-- Chỉ có 1 DataNode nên mỗi block chỉ lưu 1 bản (mặc định là 3 bản) -->
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
  <!-- NameNode lưu METADATA ở đây: cây thư mục, file nào gồm những block nào -->
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file://$DATA_DIR/namenode</value>
  </property>
  <!-- DataNode lưu các BLOCK dữ liệu thật ở đây -->
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file://$DATA_DIR/datanode</value>
  </property>
</configuration>
EOF

cat > "$HADOOP_CONF_DIR/mapred-site.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <!-- Chạy job MapReduce trên YARN (không có dòng này thì job chỉ chạy cục bộ trong 1 tiến trình) -->
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
  <!-- Nơi container của YARN tìm thư viện MapReduce -->
  <property>
    <name>mapreduce.application.classpath</name>
    <value>$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>
  </property>
</configuration>
EOF

cat > "$HADOOP_CONF_DIR/yarn-site.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <!-- Dịch vụ shuffle: chuyển output của Map sang cho Reduce -->
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <!-- Các biến môi trường được truyền vào container (theo tài liệu chính thức của Hadoop) -->
  <property>
    <name>yarn.nodemanager.env-whitelist</name>
    <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME</value>
  </property>
  <!-- Mặc định ổ đĩa đầy quá 90% thì YARN coi là "hỏng" và KHÔNG chạy task nào
       (job treo mãi ở trạng thái ACCEPTED). Ổ máy này đang đầy ~98% nên nâng ngưỡng lên. -->
  <property>
    <name>yarn.nodemanager.disk-health-checker.max-disk-utilization-per-disk-percentage</name>
    <value>99.9</value>
  </property>
  <!-- Tắt kiểm tra bộ nhớ ảo: JVM trên máy nhiều nhân "xin" nhiều bộ nhớ ảo, dễ bị YARN kill oan -->
  <property>
    <name>yarn.nodemanager.vmem-check-enabled</name>
    <value>false</value>
  </property>
</configuration>
EOF
echo "Đã ghi: hadoop-env.sh, core-site.xml, hdfs-site.xml, mapred-site.xml, yarn-site.xml"

step "4. Format HDFS (khởi tạo NameNode rỗng, chỉ làm 1 lần duy nhất)"
if [[ -d $DATA_DIR/namenode/current ]]; then
  echo "NameNode đã được format trước đó -> bỏ qua (format lại sẽ MẤT dữ liệu trên HDFS)."
else
  run hdfs namenode -format -nonInteractive
fi

step "Xong! Bước tiếp theo: bash scripts/start_hadoop.sh"
