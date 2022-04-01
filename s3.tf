data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]
    principals {
      type        = "AWS"
      identifiers = ["582318560864"]
    }
  }
}


resource "aws_s3_bucket" "alb_log" {
  bucket = "${var.system_name}-${var.env_name}-alb-log-bucket"
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_log_lifecycle" {
  bucket = aws_s3_bucket.alb_log.id
  rule {
    id     = "log"
    status = "Enabled"
    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}