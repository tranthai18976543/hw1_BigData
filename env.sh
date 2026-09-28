# Biến môi trường cho Hadoop. Mỗi khi mở terminal mới, chạy:   source env.sh

if [[ -z ${JAVA_HOME:-} ]]; then
  # /usr/lib/jvm/java-11-openjdk-amd64/bin/javac  ->  /usr/lib/jvm/java-11-openjdk-amd64
  JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$(command -v javac || command -v java)")")")
  export JAVA_HOME
fi

export HADOOP_HOME=$HOME/hadoop                 # nơi cài Hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop  # nơi chứa các file cấu hình *.xml

case ":$PATH:" in
  *":$HADOOP_HOME/bin:"*) ;;                    # đã có trong PATH rồi thì thôi
  *) export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH ;;
esac
