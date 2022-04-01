data "aws_iam_policy_document" "codebuild" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectLogGroup",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "secretsmanager:GetSecretValue",
      "codestar-connections:UseConnection",
      "ecs:DescribeTaskDefinition"
    ]
  }
}

data "aws_caller_identity" "self" {}

output "account_id" {
  value = "${data.aws_caller_identity.self.account_id}"
}

module "codebuild_role" {
  source      = "./module/iam_role"
  name        = "${var.system_name}-${var.env_name}-build-role"
  identifiers = "codebuild.amazonaws.com"
  policy      = data.aws_iam_policy_document.codebuild.json
}

resource "aws_codebuild_project" "build" {
  name         = "${var.system_name}-${var.env_name}-build"
  service_role = module.codebuild_role.iam_role_arn
  source {
    type = "CODEPIPELINE"
  }
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    type            = "LINUX_CONTAINER"
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:3.0"
    privileged_mode = true
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "${data.aws_caller_identity.self.account_id}"
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = "sample-container"
    }
    environment_variable {
      name  = "ECS_TASK_DEFINITION_ARN"
      value = aws_ecs_task_definition.task_definition.arn
    }
  }
}