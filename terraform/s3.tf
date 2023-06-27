resource "aws_s3_bucket" "tiny_url_bucket" {
  bucket = "tiny-url-bucket-${var.environment}"
}

resource "aws_s3_bucket_website_configuration" "tiny_url_bucket_website_configuration" {
  bucket = aws_s3_bucket.tiny_url_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "tiny_url_bucket_access_block" {
  bucket = aws_s3_bucket.tiny_url_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "tiny_url_bucket_policy_document" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.tiny_url_bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "tiny_url_bucket_policy" {
  bucket = aws_s3_bucket.tiny_url_bucket.id
  policy = data.aws_iam_policy_document.tiny_url_bucket_policy_document.json

  depends_on = [
    aws_s3_bucket.tiny_url_bucket,
    aws_s3_bucket_public_access_block.tiny_url_bucket_access_block,
    data.aws_iam_policy_document.tiny_url_bucket_policy_document,
  ]
}

resource "aws_s3_bucket_lifecycle_configuration" "tiny_url_bucket_lifecycle_configuration" {
  bucket = aws_s3_bucket.tiny_url_bucket.id

  rule {
    id     = "delete-after-seven-days"
    status = "Enabled"
    filter {}
    expiration {
      days = 7
    }
  }
}
