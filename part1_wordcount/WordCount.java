/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ĐÂY LÀ BẢN SAO ĐỂ ĐỌC HIỂU: mã nguồn gốc của ví dụ "wordcount" nằm trong
// $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.3.jar
// (lấy từ .../mapreduce/sources/hadoop-mapreduce-examples-3.4.3-sources.jar).
// Code giữ nguyên, chỉ thêm chú thích tiếng Việt.

package org.apache.hadoop.examples;

import java.io.IOException;
import java.util.StringTokenizer;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;

public class WordCount {

  // ---------------- MAP ----------------
  // Mapper<KEYIN, VALUEIN, KEYOUT, VALUEOUT>
  //   input : (vị trí byte của dòng, nội dung dòng)
  //   output: (từ, 1)
  public static class TokenizerMapper
       extends Mapper<Object, Text, Text, IntWritable>{

    private final static IntWritable one = new IntWritable(1);
    private Text word = new Text();

    // Được gọi 1 lần cho MỖI DÒNG của file input
    public void map(Object key, Text value, Context context
                    ) throws IOException, InterruptedException {
      StringTokenizer itr = new StringTokenizer(value.toString());   // tách dòng theo khoảng trắng
      while (itr.hasMoreTokens()) {
        word.set(itr.nextToken());
        context.write(word, one);                                     // phát ra cặp (từ, 1)
      }
    }
  }

  // ---------------- REDUCE ----------------
  //   input : (từ, [1, 1, 1, ...])  <- Hadoop đã gom mọi giá trị cùng key lại (shuffle & sort)
  //   output: (từ, tổng)
  public static class IntSumReducer
       extends Reducer<Text,IntWritable,Text,IntWritable> {
    private IntWritable result = new IntWritable();

    // Được gọi 1 lần cho MỖI TỪ khác nhau
    public void reduce(Text key, Iterable<IntWritable> values,
                       Context context
                       ) throws IOException, InterruptedException {
      int sum = 0;
      for (IntWritable val : values) {
        sum += val.get();
      }
      result.set(sum);
      context.write(key, result);
    }
  }

  // ---------------- DRIVER: cấu hình và nộp job ----------------
  public static void main(String[] args) throws Exception {
    Configuration conf = new Configuration();
    String[] otherArgs = new GenericOptionsParser(conf, args).getRemainingArgs();
    if (otherArgs.length < 2) {
      System.err.println("Usage: wordcount <in> [<in>...] <out>");
      System.exit(2);
    }
    Job job = Job.getInstance(conf, "word count");
    job.setJarByClass(WordCount.class);
    job.setMapperClass(TokenizerMapper.class);
    job.setCombinerClass(IntSumReducer.class);    // tối ưu: cộng bớt ngay ở phía Map (combiner)
    job.setReducerClass(IntSumReducer.class);
    job.setOutputKeyClass(Text.class);            // kiểu của key output: Text (từ)
    job.setOutputValueClass(IntWritable.class);   // kiểu của value output: số nguyên (số lần)
    for (int i = 0; i < otherArgs.length - 1; ++i) {
      FileInputFormat.addInputPath(job, new Path(otherArgs[i]));
    }
    FileOutputFormat.setOutputPath(job,
      new Path(otherArgs[otherArgs.length - 1]));
    System.exit(job.waitForCompletion(true) ? 0 : 1);   // nộp job lên YARN và chờ chạy xong
  }
}
