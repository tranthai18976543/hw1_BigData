# Homework 1: Hadoop WordCount & đếm K-mer

**Sinh viên thực hiện:** _(Trần Quốc Thái  –  20230065)_
**Đề bài:** [Homework 1-1.pdf](Homework%201-1.pdf)

Bài gồm 2 phần, đều chạy trên Hadoop 3.4.3 (chế độ pseudo-distributed, đủ HDFS + YARN):

1. Chạy chương trình WordCount có sẵn của Hadoop trên bộ Kinh Thánh + toàn tập Shakespeare, tìm 10 từ xuất hiện nhiều nhất.
2. Tự cài đặt chương trình đếm k-mer (Python + Hadoop Streaming, và thêm một bản Java), tìm 10 9-mer xuất hiện nhiều nhất trong bộ gen E. coli.

---

## Kết quả

### Câu 1: 10 từ xuất hiện nhiều nhất

Dữ liệu `bible+shakes.nopunc`: 156.215 dòng, 1.734.298 từ, 41.788 từ khác nhau.

| Hạng | Từ | Số lần |
|---:|---|---:|
| 1 | the | 93.739 |
| 2 | and | 79.182 |
| 3 | of | 53.121 |
| 4 | to | 33.929 |
| 5 | i | 30.240 |
| 6 | that | 24.407 |
| 7 | in | 24.350 |
| 8 | a | 23.504 |
| 9 | my | 17.312 |
| 10 | he | 17.087 |

### Câu 2: 10 9-mer xuất hiện nhiều nhất trong E. coli

Dữ liệu `ecoli.fa` (E. coli K-12 MG1655, NC_000913.2): bộ gen dài 4.639.675 base, gồm 4.639.667 9-mer, trong đó 256.527 9-mer khác nhau.

| Hạng | 9-mer | Số lần |
|---:|---|---:|
| 1 | CAGCGCCAG | 294 |
| 2 | CCAGCGCCA | 290 |
| 3 | GCGCTGGCG | 273 |
| 4 | CTGGCGCTG | 253 |
| 5 | CGCTGGCGG | 249 |
| 5 | TGGCGCTGG | 249 |
| 7 | CGCCAGCAG | 244 |
| 7 | CGCCAGCGC | 244 |
| 9 | GCCAGCGCC | 241 |
| 10 | CCGCCAGCA | 231 |
| 10 | CGCTGGCGC | 231 |

Vị trí thứ 10 có 2 9-mer đồng hạng (cùng 231 lần), nên bảng có 11 dòng.

### Nhận xét

- Câu 1: cả 10 từ đứng đầu đều là hư từ (the, and, of, to…), đúng với đặc điểm của văn bản tiếng Anh.
- Câu 2: các 9-mer đứng đầu đều giàu G/C và đi thành cặp bổ sung ngược (reverse complement) của nhau:
  #1 CAGCGCCAG ↔ #4 CTGGCGCTG, #2 CCAGCGCCA ↔ #6 TGGCGCTGG, #3 GCGCTGGCG ↔ #8 CGCCAGCGC.
  Lý do là gen nằm trên cả 2 mạch DNA.

Kết quả đầy đủ: [part1_wordcount/output/part-r-00000](part1_wordcount/output/part-r-00000) và
[part2_kmer/output_streaming_k9/part-00000](part2_kmer/output_streaming_k9/part-00000).

---

## Môi trường

| Thành phần | Phiên bản |
|---|---|
| Hệ điều hành | Ubuntu 22.04 |
| Java | OpenJDK 11 |
| Python | 3.10 |
| Hadoop | 3.4.3, pseudo-distributed: NameNode, DataNode, ResourceManager, NodeManager, JobHistoryServer trên 1 máy |

## Cấu trúc thư mục

```
├── README.md
├── Homework 1-1.pdf             đề bài
├── env.sh                       biến môi trường (JAVA_HOME, HADOOP_HOME, PATH)
├── scripts/
│   ├── install_hadoop.sh        cài và cấu hình Hadoop pseudo-distributed vào ~/hadoop
│   ├── start_hadoop.sh          bật HDFS, YARN, JobHistory
│   ├── stop_hadoop.sh           tắt
│   └── common.sh                hàm dùng chung (in lệnh trước khi chạy)
├── data/
│   ├── bible+shakes.nopunc      dữ liệu câu 1
│   └── ecoli.fa                 dữ liệu câu 2
├── part1_wordcount/
│   ├── WordCount.java           mã nguồn ví dụ wordcount của Hadoop (bản sao, có chú thích)
│   ├── run_wordcount.sh
│   └── output/                  kết quả tải về từ HDFS
└── part2_kmer/
    ├── mapper.py, reducer.py    cài đặt bằng Python + Hadoop Streaming
    ├── run_kmer_streaming.sh
    ├── KmerCount.java           cài đặt bằng Java MapReduce
    ├── run_kmer_java.sh
    └── output_streaming_k9/     kết quả tải về từ HDFS
```

---

## Cách chạy lại

**Yêu cầu:** Linux, Java 8 hoặc 11 (cần JDK nếu chạy bản Java), Python 3, `curl`, khoảng 2 GB ổ đĩa trống. Không cần quyền sudo.

```bash
# 1. Cài Hadoop (chỉ một lần): tải Hadoop 3.4.3, kiểm tra SHA-512, giải nén vào ~/hadoop,
#    ghi cấu hình, format HDFS
bash scripts/install_hadoop.sh

# 2. Bật Hadoop
source env.sh
bash scripts/start_hadoop.sh

# 3. Chạy từng phần. Mỗi script in ra từng lệnh trước khi chạy:
#    put dữ liệu lên HDFS → chạy job → lấy kết quả về → sort lấy top 10
bash part1_wordcount/run_wordcount.sh      # câu 1
bash part2_kmer/run_kmer_streaming.sh      # câu 2, Python + Hadoop Streaming (tham số tuỳ chọn: k, mặc định 9)
bash part2_kmer/run_kmer_java.sh           # câu 2, Java; cuối script so sánh với kết quả bản Python

# 4. Tắt Hadoop
bash scripts/stop_hadoop.sh
```

Giao diện web khi Hadoop đang chạy: HDFS http://localhost:9870, YARN http://localhost:8088,
JobHistory http://localhost:19888.

Các cấu hình chính do `install_hadoop.sh` ghi vào `~/hadoop/etc/hadoop/`:

| File | Thuộc tính | Giá trị | Mục đích |
|---|---|---|---|
| core-site.xml | `fs.defaultFS` | `hdfs://localhost:9000` | Địa chỉ NameNode |
| hdfs-site.xml | `dfs.replication` | `1` | Chỉ có 1 DataNode |
| hdfs-site.xml | `dfs.namenode.name.dir`, `dfs.datanode.data.dir` | `~/hadoop/data/...` | Không để dữ liệu HDFS trong `/tmp` |
| mapred-site.xml | `mapreduce.framework.name` | `yarn` | Chạy MapReduce trên YARN |
| yarn-site.xml | `yarn.nodemanager.aux-services` | `mapreduce_shuffle` | Dịch vụ shuffle |
| yarn-site.xml | `yarn.nodemanager.disk-health-checker.max-disk-utilization-per-disk-percentage` | `99.9` | Máy ít dung lượng trống: ngưỡng mặc định 90% khiến NodeManager bị đánh dấu unhealthy và job không chạy |
| yarn-site.xml | `yarn.nodemanager.vmem-check-enabled` | `false` | Tránh container bị kill vì vượt giới hạn bộ nhớ ảo |

---

## Phần 1: WordCount

Chạy ví dụ `wordcount` trong `hadoop-mapreduce-examples-3.4.3.jar`. Đây là file tương ứng với
`hadoop-examples.jar` trong đề (đề dùng đường dẫn của Hadoop 1). Các lệnh chính (chạy từ thư mục gốc;
script `run_wordcount.sh` làm đúng các bước này):

```bash
hadoop fs -mkdir -p /user/$USER/wordcount/input
hadoop fs -put data/bible+shakes.nopunc /user/$USER/wordcount/input
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.3.jar wordcount \
    /user/$USER/wordcount/input /user/$USER/wordcount/output
hadoop fs -get /user/$USER/wordcount/output output
sort -k2,2nr output/part-r-00000 | head -10
```

Cách chương trình hoạt động ([WordCount.java](part1_wordcount/WordCount.java)):

- **Map:** tách mỗi dòng theo khoảng trắng, phát ra `(từ, 1)`.
- **Reduce** (`IntSumReducer`): cộng các giá trị của cùng một từ.
- **Combiner:** chính là `IntSumReducer`, cộng gộp ngay ở phía map trước khi shuffle. Làm được vì phép cộng có tính giao hoán và kết hợp.

---

## Phần 2: Đếm k-mer

### Thiết kế

Bài toán giống WordCount, chỉ khác bước Map: trượt một cửa sổ dài k dọc chuỗi gen và phát ra `(k-mer, 1)`
cho mỗi vị trí. Reduce cộng dồn và được dùng luôn làm combiner. Có 2 cài đặt cho kết quả giống hệt nhau:

- [mapper.py](part2_kmer/mapper.py), [reducer.py](part2_kmer/reducer.py): Python, chạy bằng Hadoop Streaming.
- [KmerCount.java](part2_kmer/KmerCount.java): Java MapReduce, sửa từ WordCount. Tham số k truyền qua `-D kmer.k=9`.

Lệnh chạy bản Streaming (trong thư mục `part2_kmer/`; xem `run_kmer_streaming.sh`):

```bash
hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.4.3.jar \
  -D mapreduce.input.fileinputformat.split.minsize=9223372036854775807 \
  -files mapper.py,reducer.py \
  -mapper "python3 mapper.py 9" \
  -combiner "python3 reducer.py" \
  -reducer "python3 reducer.py" \
  -input /user/$USER/kmer/input \
  -output /user/$USER/kmer/output_streaming_k9
```

### Hai vấn đề cần xử lý

**1. Chuỗi gen bị ngắt dòng.** File FASTA chia bộ gen thành 66.282 dòng, mỗi dòng 70 ký tự, còn Hadoop
đưa input cho mapper theo từng dòng. Nếu chỉ cắt k-mer trong từng dòng thì các k-mer vắt qua chỗ xuống
dòng bị bỏ sót:

| Cách làm | Tổng số 9-mer | Hạng 1 |
|---|---:|---|
| Chỉ cắt k-mer trong từng dòng | 4.109.422 (thiếu 530.245, khoảng 11%) | CCAGCGCCA, 258 lần (sai) |
| Nối qua chỗ xuống dòng (bài làm) | 4.639.667 | CAGCGCCAG, 294 lần |

Mapper giữ lại k − 1 ký tự cuối của dòng trước (`tail`) và nối vào đầu dòng sau. `tail` chỉ dài k − 1 ký
tự nên không sinh k-mer trùng. Gặp dòng tiêu đề `>` thì `tail` được xoá, để không nối k-mer qua 2 chuỗi khác nhau.

**2. Hadoop chia input thành nhiều split.** Cách trên đòi hỏi một mapper đọc các dòng liên tiếp theo đúng
thứ tự. Hadoop Streaming dùng API `mapred` cũ với mặc định `mapreduce.job.maps=2`, nên file 4,7 MB bị chia
thành 2 split. Kết quả là mất đúng k − 1 = 8 k-mer ở chỗ cắt (tổng chỉ còn 4.639.659). Cả 2 cài đặt đều
đặt kích thước split tối thiểu bằng `Long.MAX_VALUE`, để mỗi file FASTA là đúng một split:

- Streaming: `-D mapreduce.input.fileinputformat.split.minsize=9223372036854775807`
- Java: `FileInputFormat.setMinInputSplitSize(job, Long.MAX_VALUE)`

Ngoài ra, k-mer chứa ký tự `N` (base chưa xác định) được bỏ qua. Bộ gen E. coli này không có `N` nên
kết quả không bị ảnh hưởng. Chương trình chỉ đếm trên một mạch, đúng như ví dụ `ACACACAGT` của đề,
không gộp một k-mer với chuỗi bổ sung ngược của nó.

### Kiểm chứng

- `mapper | sort | reducer` chạy trên ví dụ `ACACACAGT` với k = 3 cho đúng kết quả trong đề: ACA 3, AGT 1, CAC 2, CAG 1.
- Tổng số lần đếm = 4.639.667 = N − k + 1 (N = 4.639.675).
- Output của bản Java và bản Python giống hệt nhau (`diff` không có khác biệt).
- Top 10 khớp với kết quả đếm trực tiếp bằng Python thuần, không qua Hadoop.

---

## Số liệu khi chạy

| Counter | WordCount | K-mer (k = 9, Streaming) |
|---|---:|---:|
| Số split / map task | 1 | 1 |
| Map input records | 156.215 | 66.283 |
| Map output records | 1.734.298 | 4.639.667 |
| Combine output records | 41.788 (giảm 97,6%) | khoảng 493 nghìn (giảm 89%) |
| Reduce output records | 41.788 | 256.527 |
| Thời gian chạy job | khoảng 13 giây | khoảng 15 giây |

Ở câu 2, Combine output lớn hơn số k-mer khác nhau. Lý do: output của map vượt bộ đệm sort (100 MB) nên
bị ghi tràn (spill) ra đĩa 2 lần, combiner chạy riêng trên từng lần; reducer cộng gộp phần còn lại.

## Giới hạn

- Mỗi file FASTA chỉ do một mapper xử lý, nên không song song hoá được bên trong một file. Với E. coli
  (4,7 MB, nhỏ hơn 1 block 128 MB) điều này không ảnh hưởng. Với bộ gen lớn cần tách mỗi nhiễm sắc thể
  thành một file, hoặc tiền xử lý thành các bản ghi chồng lên nhau k − 1 ký tự.
