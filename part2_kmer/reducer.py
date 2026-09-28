#!/usr/bin/env python3
"""reducer.py - Reducer cộng dồn số đếm cho Hadoop Streaming.

Input : các dòng "KEY<TAB>COUNT" ĐÃ ĐƯỢC SẮP XẾP theo KEY (Hadoop tự sort ở pha
        shuffle), nên các dòng cùng KEY luôn nằm liền nhau.
Output: mỗi KEY một dòng "KEY<TAB>TỔNG".

Vì input và output cùng dạng "KEY<TAB>SỐ", file này dùng được làm cả combiner.

Chạy thử:
    printf '>chr1\nACACACAGT\n' | python3 mapper.py 3 | sort | python3 reducer.py
"""
import sys

current_key = None
current_count = 0

for line in sys.stdin:
    key, count = line.rstrip("\n").split("\t", 1)
    count = int(count)

    if key == current_key:            # vẫn là KEY cũ -> cộng tiếp
        current_count += count
    else:                             # sang KEY mới -> in kết quả của KEY cũ
        if current_key is not None:
            print(f"{current_key}\t{current_count}")
        current_key = key
        current_count = count

if current_key is not None:           # đừng quên KEY cuối cùng
    print(f"{current_key}\t{current_count}")
