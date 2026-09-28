#!/usr/bin/env bash
# Phần 2 - cách 1: Python + Hadoop Streaming, đếm k-mer trong bộ gen E. coli
#   bash part2_kmer/run_kmer_streaming.sh        # k = 9 (đề bài)
#   bash part2_kmer/run_kmer_streaming.sh 3      # thử k khác
set -eu
source "$(dirname "$0")/../scripts/common.sh"
cd "$(dirname "$0")"

K=${1:-9}
IN=/user/$USER/kmer/input
OUT=/user/$USER/kmer/output_streaming_k$K
LOCAL_OUT=output_streaming_k$K
STREAMING_JAR=$(ls "$HADOOP_HOME"/share/hadoop/tools/lib/hadoop-streaming-*.jar)

step "0. Thử mapper/reducer ngay trên máy với ví dụ của đề (ACACACAGT, k=3), chưa cần Hadoop"
runp "printf '>chr1\nACACACAGT\n' | python3 mapper.py 3"
runp "printf '>chr1\nACACACAGT\n' | python3 mapper.py 3 | sort | python3 reducer.py"

step "1. Đưa bộ gen lên HDFS"
run hadoop fs -mkdir -p "$IN"
run hadoop fs -put -f ../data/ecoli.fa "$IN"
run hadoop fs -ls "$IN"

step "2. Xoá output cũ (Hadoop báo lỗi nếu output đã tồn tại)"
run hadoop fs -rm -r -f "$OUT"

step "3. Chạy job Hadoop Streaming: mapper, combiner, reducer đều là script Python"
# Mapper phải đọc các dòng của chuỗi gen LIÊN TIẾP nhau (để nối k-mer qua chỗ xuống dòng),
# nên không được cắt file cho nhiều mapper. Mặc định Streaming cắt file này làm 2 split
# (mapreduce.job.maps=2) -> mất k-1 k-mer ở chỗ cắt. Đặt kích thước split tối thiểu cực lớn
# (= Long.MAX_VALUE) -> mỗi file là đúng 1 split -> 1 mapper đọc trọn file từ đầu đến cuối.
NO_SPLIT=9223372036854775807
run hadoop jar "$STREAMING_JAR" \
  -D mapreduce.job.name="kmer_count_k${K}_python" \
  -D mapreduce.input.fileinputformat.split.minsize=$NO_SPLIT \
  -files mapper.py,reducer.py \
  -mapper "python3 mapper.py $K" \
  -combiner "python3 reducer.py" \
  -reducer "python3 reducer.py" \
  -input "$IN" \
  -output "$OUT"

step "4. Tải kết quả về máy"
rm -rf "$LOCAL_OUT"
run hadoop fs -get "$OUT" "$LOCAL_OUT"

step "5. Kiểm tra: tổng số k-mer đếm được phải bằng (độ dài bộ gen - k + 1)"
GENOME_LEN=$(grep -v '>' ../data/ecoli.fa | tr -d '\n' | wc -c)
echo "Độ dài bộ gen = $GENOME_LEN  =>  số k-mer mong đợi = $GENOME_LEN - $K + 1 = $((GENOME_LEN - K + 1))"
runp "awk -F'\t' '{n++; s+=\$2} END {print n \" k-mer khác nhau, tổng cộng \" s \" k-mer\"}' $LOCAL_OUT/part-*"

step "6. Trả lời câu hỏi: 10 k-mer xuất hiện nhiều nhất"
runp "sort -k2,2nr $LOCAL_OUT/part-* | head -10"
echo "Xem thêm dòng 11-12 để biết vị trí thứ 10 có bị đồng hạng không:"
runp "sort -k2,2nr $LOCAL_OUT/part-* | sed -n '11,12p'"
