#!/usr/bin/env bash
# Phần 2 - cách 2: Java MapReduce (viết theo mẫu WordCount), đếm k-mer trong bộ gen E. coli
#   bash part2_kmer/run_kmer_java.sh        # k = 9
#   bash part2_kmer/run_kmer_java.sh 3      # thử k khác
set -eu
source "$(dirname "$0")/../scripts/common.sh"
cd "$(dirname "$0")"

K=${1:-9}
IN=/user/$USER/kmer/input
OUT=/user/$USER/kmer/output_java_k$K

step "1. Biên dịch KmerCount.java (dùng thư viện của Hadoop) rồi đóng gói thành kmercount.jar"
rm -rf build && mkdir build
runp 'javac -encoding UTF-8 -cp "$(hadoop classpath)" -d build KmerCount.java'
run jar -cf kmercount.jar -C build .

step "2. Đưa bộ gen lên HDFS"
run hadoop fs -mkdir -p "$IN"
run hadoop fs -put -f ../data/ecoli.fa "$IN"

step "3. Xoá output cũ"
run hadoop fs -rm -r -f "$OUT"

step "4. Chạy job (tham số k truyền qua -D kmer.k=...)"
run hadoop jar kmercount.jar KmerCount -D kmer.k="$K" "$IN" "$OUT"

step "5. Top 10 k-mer"
runp "hadoop fs -cat $OUT/part-r-* | sort -k2,2nr | head -10"

if hadoop fs -test -d "/user/$USER/kmer/output_streaming_k$K"; then
  step "6. So sánh với kết quả của bản Python"
  runp "diff <(hadoop fs -cat $OUT/part-*) <(hadoop fs -cat /user/$USER/kmer/output_streaming_k$K/part-*) && echo 'GIỐNG HỆT NHAU'"
fi
