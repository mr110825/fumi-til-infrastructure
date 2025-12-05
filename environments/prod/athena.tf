# ===========================================
# Athenaクエリ結果保存用S3バケット
# ===========================================
resource "aws_s3_bucket" "athena_results" {
  bucket = "fumi-til-athena-results"

  tags = {
    Name = "fumi-til-athena-results"
  }
}

# パブリックアクセスを完全にブロック
resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ライフサイクルルール：7日でクエリ結果を自動削除
resource "aws_s3_bucket_lifecycle_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    id     = "delete-old-query-results"
    status = "Enabled"

    filter {}

    expiration {
      days = 7 # クエリ結果は長期保存不要のため7日で削除
    }
  }
}

# ===========================================
# Athena Workgroup
# クエリ結果の保存先やタイムアウト等を一元管理
# ===========================================
resource "aws_athena_workgroup" "main" {
  name = "fumi-til-workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/query-results/"
    }

    # Workgroupの設定を強制（個別クエリでの上書きを禁止）
    enforce_workgroup_configuration = true
  }

  tags = {
    Name = "fumi-til-workgroup"
  }
}

# ===========================================
# Glue Database
# AthenaはGlue Data Catalogをメタデータストアとして使用
# ===========================================
resource "aws_glue_catalog_database" "cloudfront_logs" {
  name = "fumi_til_logs"
}

# ===========================================
# Glue Table（CloudFrontログ用）
# CloudFrontの標準ログフォーマット（33カラム）に対応
# 参考: https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html
# ===========================================
resource "aws_glue_catalog_table" "cloudfront_logs" {
  name          = "cloudfront_logs"
  database_name = aws_glue_catalog_database.cloudfront_logs.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "skip.header.line.count" = "2" # CloudFrontログは2行のヘッダーがあるためスキップ
    "EXTERNAL"               = "TRUE"
  }

  storage_descriptor {
    location      = "s3://fumi-til-logs/cloudfront/" # CloudFrontログの保存先
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim" = "\t" # CloudFrontログはタブ区切り
      }
    }

    # CloudFront標準ログの33カラム定義
    # 各カラムの意味は公式ドキュメント参照
    columns {
      name = "date"
      type = "date"
    }
    columns {
      name = "time"
      type = "string"
    }
    columns {
      name = "x_edge_location" # エッジロケーション（例: NRT51-C1）
      type = "string"
    }
    columns {
      name = "sc_bytes" # レスポンスのバイト数
      type = "bigint"
    }
    columns {
      name = "c_ip" # クライアントIP
      type = "string"
    }
    columns {
      name = "cs_method" # HTTPメソッド（GET, POST等）
      type = "string"
    }
    columns {
      name = "cs_host" # リクエスト先ホスト
      type = "string"
    }
    columns {
      name = "cs_uri_stem" # リクエストURI（クエリ文字列除く）
      type = "string"
    }
    columns {
      name = "sc_status" # HTTPステータスコード
      type = "int"
    }
    columns {
      name = "cs_referer" # リファラー
      type = "string"
    }
    columns {
      name = "cs_user_agent" # ユーザーエージェント
      type = "string"
    }
    columns {
      name = "cs_uri_query" # クエリ文字列
      type = "string"
    }
    columns {
      name = "cs_cookie" # Cookie
      type = "string"
    }
    columns {
      name = "x_edge_result_type" # キャッシュ結果（Hit, Miss, Error等）
      type = "string"
    }
    columns {
      name = "x_edge_request_id" # リクエストID
      type = "string"
    }
    columns {
      name = "x_host_header" # Hostヘッダー
      type = "string"
    }
    columns {
      name = "cs_protocol" # プロトコル（http, https）
      type = "string"
    }
    columns {
      name = "cs_bytes" # リクエストのバイト数
      type = "bigint"
    }
    columns {
      name = "time_taken" # リクエスト処理時間（秒）
      type = "double"
    }
    columns {
      name = "x_forwarded_for" # X-Forwarded-Forヘッダー
      type = "string"
    }
    columns {
      name = "ssl_protocol" # SSLプロトコル（TLSv1.2等）
      type = "string"
    }
    columns {
      name = "ssl_cipher" # SSL暗号スイート
      type = "string"
    }
    columns {
      name = "x_edge_response_result_type" # オリジンからのレスポンス結果
      type = "string"
    }
    columns {
      name = "cs_protocol_version" # HTTPバージョン
      type = "string"
    }
    columns {
      name = "fle_status" # フィールドレベル暗号化ステータス
      type = "string"
    }
    columns {
      name = "fle_encrypted_fields" # 暗号化されたフィールド数
      type = "string"
    }
    columns {
      name = "c_port" # クライアントポート
      type = "int"
    }
    columns {
      name = "time_to_first_byte" # 最初のバイトまでの時間（秒）
      type = "double"
    }
    columns {
      name = "x_edge_detailed_result_type" # 詳細な結果タイプ
      type = "string"
    }
    columns {
      name = "sc_content_type" # Content-Type
      type = "string"
    }
    columns {
      name = "sc_content_len" # Content-Length
      type = "bigint"
    }
    columns {
      name = "sc_range_start" # Rangeリクエストの開始位置
      type = "bigint"
    }
    columns {
      name = "sc_range_end" # Rangeリクエストの終了位置
      type = "bigint"
    }
  }
}

# ===========================================
# Outputs
# ===========================================
output "athena_workgroup" {
  description = "Athena Workgroup名"
  value       = aws_athena_workgroup.main.name
}

output "athena_database" {
  description = "Glue Database名（CloudFrontログ用）"
  value       = aws_glue_catalog_database.cloudfront_logs.name
}

output "athena_table" {
  description = "Glue Table名（CloudFrontログ用）"
  value       = aws_glue_catalog_table.cloudfront_logs.name
}

output "athena_results_bucket" {
  description = "Athenaクエリ結果保存用S3バケット"
  value       = aws_s3_bucket.athena_results.bucket
}
