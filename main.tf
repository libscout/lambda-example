terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
#  required_version = ">= 5.0.*"
}


provider "aws" {
  profile = var.AWS_CLI_PROFILE
  region = var.AWS_DEFAULT_REGION
}

data "archive_file" "lambda_example_fn" {
  output_path = "${path.root}/zip/index.js.zip"
  source_file = "${path.root}/js/index.js"
  type        = "zip"
  output_file_mode = "0666"
}



resource "aws_lambda_function" "lambda_example" {
  function_name = "SSMLAmbdaExample"
  role          = aws_iam_role.lambda_iam_role.arn
  runtime = "nodejs16.x"
  filename = data.archive_file.lambda_example_fn.output_path
  source_code_hash = data.archive_file.lambda_example_fn.output_base64sha256
  handler = "index.handler"
  environment {

    variables = {
      TEST_ENVIRONMENT = aws_ssm_parameter.ssm_parameter.value
      TEST_ENVIRONMENT_SECURE = aws_ssm_parameter.ssm_parameter_secure.value
    }
  }
}


resource "aws_iam_role" "lambda_iam_role" {
  name_prefix = "LambdaSSMParameterRole_"
  assume_role_policy = data.aws_iam_policy_document.test.json
  managed_policy_arns = [
    data.aws_iam_policy.lambda_basic_iam.arn,
    aws_iam_policy.lambda_policy.arn
  ]
}

data "aws_iam_policy" "lambda_basic_iam" {
  name = "AWSLambdaBasicExecutionRole"
}

data aws_iam_policy_document "test" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    sid = ""
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

data aws_iam_policy_document "policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter",
      "ssm:GetParametersByPath"
    ]
    resources = [
      "arn:aws:ssm:${var.AWS_DEFAULT_REGION}:${var.AWS_ACCOUNT_ID}:parameter/example-1/*",
      aws_ssm_parameter.ssm_parameter.arn,
    ]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name_prefix = "lambda_policy_"
  policy = data.aws_iam_policy_document.policy_doc.json
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ssm_parameter" "ssm_parameter" {
  name = "TEST_ENVIRONMENT"
  type = "String"
  value = "TEST_ENVIRONMENT_VALUE"
}

#resource "aws_ssm_parameter" "folder" {
#  name = "/example-1/"
#  type = "String"
#  value = "1"
#}

#data "aws_ssm_parameters_by_path" "ssm_parameters_folder" {
#  path = "/example-1/"
#  recursive = true
#  with_decryption = true
#}

resource "aws_ssm_parameter" "ssm_parameter_secure" {
  name = "TEST_ENVIRONMENT_SECURE"
  type = "SecureString"
  value = "TEST_ENVIRONMENT_VALUE_SECURE"
}