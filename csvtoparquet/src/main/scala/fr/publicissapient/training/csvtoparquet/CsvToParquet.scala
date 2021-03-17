package fr.publicissapient.training.csvtoparquet

import com.amazonaws.services.glue.GlueContext
import com.amazonaws.services.glue.util.{GlueArgParser, Job}
import org.apache.log4j.Logger
import org.apache.spark.SparkContext
import org.apache.spark.sql.{SaveMode, SparkSession}


object CsvToParquet {
  def main(sysArgs: Array[String]) {
    // val sc: SparkContext = new SparkContext("local[*]", "CsvToParquet")
    val sc: SparkContext = new SparkContext()
    val glueContext: GlueContext = new GlueContext(sc)
    val spark: SparkSession = glueContext.getSparkSession

    val logger = Logger.getLogger(getClass.getName)

    logger.info(s"Executing Glue Job with parameters: ${sysArgs.mkString(", ")}")

    val args = GlueArgParser.getResolvedOptions(sysArgs, Seq("JOB_NAME", "input_path", "output_path").toArray)
    Job.init(args("JOB_NAME"), glueContext, args.asJava)

    val inputPath = args("input_path")
    val outputPath = args("output_path")

    logger.info(s"Reading data at $inputPath")
    val data = spark.read
      .option("header", "true")
      .option("delimiter", ";")
      .csv(inputPath)

    logger.info(s"Writing data at $outputPath")
    data.write.mode(SaveMode.Overwrite).parquet(outputPath)

    Job.commit()
  }
}