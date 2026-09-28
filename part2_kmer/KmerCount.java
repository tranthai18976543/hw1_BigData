import java.io.IOException;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;

/**
 * Đếm k-mer bằng Hadoop MapReduce (Java), viết theo mẫu WordCount.
 * Khác WordCount ở đúng một chỗ là hàm map(): thay vì tách dòng thành các TỪ,
 * ta cắt chuỗi gen thành các k-mer chồng lên nhau.
 *
 *   hadoop jar kmercount.jar KmerCount -D kmer.k=9 <input> <output>
 */
public class KmerCount {

  // ---------------- MAP: (vị trí dòng, dòng FASTA) -> (k-mer, 1) ----------------
  public static class KmerMapper extends Mapper<LongWritable, Text, Text, IntWritable> {
    private static final IntWritable ONE = new IntWritable(1);
    private final Text kmer = new Text();
    private int k;
    // (k-1) ký tự cuối của dòng trước, để không bỏ sót k-mer nằm vắt qua chỗ xuống dòng.
    // Làm được vì mỗi mapper đọc các dòng trong phần dữ liệu (split) của nó theo đúng thứ tự.
    private String tail = "";

    @Override
    protected void setup(Context context) {           // chạy 1 lần, trước dòng đầu tiên
      k = context.getConfiguration().getInt("kmer.k", 9);
    }

    @Override
    public void map(LongWritable offset, Text value, Context context)
        throws IOException, InterruptedException {
      String line = value.toString().trim();
      if (line.isEmpty()) {
        return;
      }
      if (line.startsWith(">")) {                      // dòng tiêu đề -> bắt đầu chuỗi gen mới
        tail = "";
        return;
      }
      String seq = tail + line.toUpperCase();
      for (int i = 0; i + k <= seq.length(); i++) {
        String s = seq.substring(i, i + k);
        if (s.indexOf('N') < 0) {                       // bỏ qua k-mer chứa base chưa xác định (N)
          kmer.set(s);
          context.write(kmer, ONE);                     // phát ra cặp (k-mer, 1)
        }
      }
      tail = seq.substring(Math.max(0, seq.length() - (k - 1)));   // giữ lại k-1 ký tự cuối
    }
  }

  // ---------------- REDUCE: giống hệt IntSumReducer của WordCount ----------------
  public static class IntSumReducer extends Reducer<Text, IntWritable, Text, IntWritable> {
    private final IntWritable result = new IntWritable();

    @Override
    public void reduce(Text key, Iterable<IntWritable> values, Context context)
        throws IOException, InterruptedException {
      int sum = 0;
      for (IntWritable val : values) {
        sum += val.get();
      }
      result.set(sum);
      context.write(key, result);
    }
  }

  // ---------------- DRIVER ----------------
  public static void main(String[] args) throws Exception {
    Configuration conf = new Configuration();
    String[] otherArgs = new GenericOptionsParser(conf, args).getRemainingArgs();  // xử lý các "-D ..."
    if (otherArgs.length != 2) {
      System.err.println("Usage: KmerCount [-D kmer.k=9] <in> <out>");
      System.exit(2);
    }
    int k = conf.getInt("kmer.k", 9);
    Job job = Job.getInstance(conf, "kmer count k=" + k + " (java)");
    job.setJarByClass(KmerCount.class);
    job.setMapperClass(KmerMapper.class);
    job.setCombinerClass(IntSumReducer.class);
    job.setReducerClass(IntSumReducer.class);
    job.setOutputKeyClass(Text.class);
    job.setOutputValueClass(IntWritable.class);
    FileInputFormat.addInputPath(job, new Path(otherArgs[0]));
    // Không cắt nhỏ file: mỗi file FASTA là đúng 1 split, do 1 mapper đọc tuần tự từ đầu đến
    // cuối -> "tail" nối được mọi chỗ xuống dòng. Nếu file bị cắt làm nhiều split thì mapper
    // của split sau không biết (k-1) ký tự cuối của split trước -> mất k-1 k-mer mỗi chỗ cắt.
    FileInputFormat.setMinInputSplitSize(job, Long.MAX_VALUE);
    FileOutputFormat.setOutputPath(job, new Path(otherArgs[1]));
    System.exit(job.waitForCompletion(true) ? 0 : 1);
  }
}
