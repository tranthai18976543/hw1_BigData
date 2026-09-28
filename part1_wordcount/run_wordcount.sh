#!/usr/bin/env bash
# Phần 1: chạy chương trình WordCount có sẵn của Hadoop trên bible+shakes.nopunc
#   bash part1_wordcount/run_wordcount.sh
set -eu
source "$(dirname "$0")/../scripts/common.sh"
cd "$(dirname "$0")"

IN=/user/$USER/wordcount/input
OUT=/user/$USER/wordcount/output
EXAMPLES_JAR=$(ls "$HADOOP_HOME"/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar)

step "1. Tạo thư mục input trên HDFS"
run hadoop fs -mkdir -p "$IN"

step "2. Đưa dữ liệu từ máy local lên HDFS"
run hadoop fs -put -f ../data/bible+shakes.nopunc "$IN"
run hadoop fs -ls "$IN"

step "3. Xoá thư mục output cũ (Hadoop báo lỗi nếu output đã tồn tại)"
run hadoop fs -rm -r -f "$OUT"

step "4. Chạy job WordCount trên YARN"
run hadoop jar "$EXAMPLES_JAR" wordcount "$IN" "$OUT"

step "5. Xem output trên HDFS và tải về máy"
run hadoop fs -ls "$OUT"
rm -rf output
run hadoop fs -get "$OUT" output
runp "head -5 output/part-r-00000"

step "6. Trả lời câu hỏi: 10 từ xuất hiện nhiều nhất"
runp "sort -k2,2nr output/part-r-00000 | head -10"
