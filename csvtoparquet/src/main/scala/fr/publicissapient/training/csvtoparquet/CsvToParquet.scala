package fr.publicissapient.training.csvtoparquet

import com.amazonaws.services.glue.{DynamicFrame, GlueContext}
import com.amazonaws.services.glue.util.{GlueArgParser, Job, JsonOptions}
import org.apache.log4j.Logger
import org.apache.spark.SparkContext
import org.apache.spark.sql.{SaveMode, SparkSession}

import scala.collection.JavaConverters.mapAsJavaMapConverter
import scala.util.Try

object CsvToParquet {

  def main(sysArgs: Array[String]) {
    // val sc: SparkContext = new SparkContext("local[*]", "CsvToParquet")

    val sc: SparkContext = new SparkContext()
    val glueContext: GlueContext = new GlueContext(sc)
    val spark: SparkSession = glueContext.getSparkSession
    val logger = Logger.getLogger(getClass.getName)
    logger.info(s"Executing Glue Job with parameters: ${sysArgs.mkString(", ")}")
    val args = GlueArgParser.getResolvedOptions(sysArgs, Array("JOB_NAME", "input_path", "output_path", "database_name", "table_name"))

    Job.init(args("JOB_NAME"), glueContext, args.asJava)
    val inputPath = args("input_path")
    val outputPath = args("output_path")
    val databaseName = args("database_name")
    val tableName = args("table_name")
    val maybePartitions = Try(GlueArgParser.getResolvedOptions(sysArgs, Array("partitions"))).toOption.map(_("partitions")).map(ujson.read(_).obj)

    val prefixToRead = maybePartitions match {
      case Some(partitions) =>
        val partitionFolders = partitions.map{ case (k, v) => s"$k=${v.str}"}.mkString("/")
        s"$inputPath/$partitionFolders"
      case None => inputPath
    }

    logger.info(s"Reading data at $prefixToRead")

    val data = spark.read
      .option("header", "true")
      .option("basePath", inputPath)
      .option("delimiter", ",")
      .csv(prefixToRead)

    logger.info(s"Writing data at $outputPath")

    val baseOptions = Map(
      "path" -> outputPath,
      "enableUpdateCatalog" -> true,
      "updateBehavior" -> "UPDATE_IN_DATABASE"
    )

    val options = maybePartitions match {
      case Some(partitions) => baseOptions + ("partitionKeys" -> partitions.keySet)
      case None => baseOptions

    }

    val dynamicFrame = DynamicFrame(data, glueContext)

    val sink = glueContext.getSink(connectionType = "s3", JsonOptions(options)).withFormat("glueparquet")
    sink.setCatalogInfo(catalogDatabase = databaseName, catalogTableName = tableName)
    sink.writeDynamicFrame(dynamicFrame)
    Job.commit()

  }

}
