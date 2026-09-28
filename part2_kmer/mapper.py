#!/usr/bin/env python3
"""mapper.py - Mapper đếm k-mer cho Hadoop Streaming.

Đọc file FASTA từ stdin. Với mỗi k-mer (đoạn con dài k ký tự, các đoạn được phép
chồng lên nhau) in ra một dòng "KMER<TAB>1" ra stdout.

Chạy thử (ví dụ trong đề bài, k = 3):
    printf '>chr1\nACACACAGT\n' | python3 mapper.py 3
"""
import sys

k = int(sys.argv[1]) if len(sys.argv) > 1 else 9

# File FASTA ngắt chuỗi gen thành nhiều dòng (ecoli.fa: 70 ký tự/dòng). Nếu chỉ cắt
# k-mer trong từng dòng thì sẽ MẤT các k-mer nằm vắt qua chỗ xuống dòng. Vì vậy ta
# giữ lại (k-1) ký tự cuối của dòng trước ("tail") và nối vào đầu dòng hiện tại.
# Cách này cần các dòng được đọc liên tiếp, theo thứ tự -> khi chạy trên Hadoop phải để
# cả file cho 1 mapper (không cắt split), xem run_kmer_streaming.sh.
tail = ""

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    if line.startswith(">"):          # dòng tiêu đề -> bắt đầu một chuỗi gen mới
        tail = ""                     # không nối k-mer qua 2 chuỗi khác nhau
        continue

    seq = tail + line.upper()
    for i in range(len(seq) - k + 1):
        kmer = seq[i:i + k]
        if "N" not in kmer:           # bỏ qua k-mer chứa base chưa xác định (N)
            print(f"{kmer}\t1")

    tail = seq[max(0, len(seq) - (k - 1)):]   # giữ lại k-1 ký tự cuối cho dòng sau
