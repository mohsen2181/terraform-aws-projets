############################################
# Glue Database
############################################
resource "aws_glue_catalog_database" "cf_logs_db" {
  name = "cloudfront_logs_db"
}

############################################
# Glue Table (CloudFront logs format)
############################################
resource "aws_glue_catalog_table" "cf_logs_table" {
  name          = "cloudfront_logs"
  database_name = aws_glue_catalog_database.cf_logs_db.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "skip.header.line.count" = "2"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.logs.bucket}/cloudfront-logs/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim" = "\t"
      }
    }

    columns {
      name = "date"
      type = "string"
    }

    columns {
      name = "time"
      type = "string"
    }

    columns {
      name = "x_edge_location"
      type = "string"
    }

    columns {
      name = "sc_bytes"
      type = "bigint"
    }

    columns {
      name = "c_ip"
      type = "string"
    }

    columns {
      name = "cs_method"
      type = "string"
    }

    columns {
      name = "cs_host"
      type = "string"
    }

    columns {
      name = "cs_uri_stem"
      type = "string"
    }

    columns {
      name = "sc_status"
      type = "int"
    }

    columns {
      name = "cs_user_agent"
      type = "string"
    }
  }
}
