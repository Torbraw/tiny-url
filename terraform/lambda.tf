data "archive_file" "tiny_url_zip" {
  type        = "zip"
  output_path = "./lambda.zip"
  source_dir  = "../dist"
}

data "aws_iam_policy_document" "tiny_url_role_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "tiny_url_role" {
  name               = "tiny-url-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.tiny_url_role_policy_document.json
}

data "aws_iam_policy_document" "tiny_url_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "tiny_url_policy" {
  name        = "tiny-url-policy"
  path        = "/"
  description = "IAM policy for tiny-url lambda"

  policy = data.aws_iam_policy_document.tiny_url_policy_document.json
}

resource "aws_iam_role_policy_attachment" "tiny_url_policy_attachment" {
  role       = aws_iam_role.tiny_url_role.name
  policy_arn = aws_iam_policy.tiny_url_policy.arn
}

resource "aws_lambda_function" "tiny_url_lambda" {
  filename         = data.archive_file.tiny_url_zip.output_path
  source_code_hash = data.archive_file.tiny_url_zip.output_base64sha256
  function_name    = "tiny-url"
  description      = "Lambda for tiny-url"
  role             = aws_iam_role.tiny_url_role.arn
  handler          = "index.handler"
  timeout          = 300

  runtime = "nodejs18.x"

  environment {
    variables = {
      region         = var.aws_region,
      logLevel       = var.aws_log_level,
      bucketName     = aws_s3_bucket.tiny_url_bucket.id
      staticEndpoint = aws_s3_bucket_website_configuration.tiny_url_bucket_website_configuration.website_endpoint
    }
  }
}

resource "aws_cloudwatch_log_group" "tiny_url_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.tiny_url_lambda.function_name}"
  retention_in_days = 7
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tiny_url_lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = aws_apigatewayv2_api.api_gateway.arn
}
