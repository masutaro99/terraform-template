data "aws_iam_policy_document" "codepipeline" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "iam:PassRole",
      "codestar-connections:UseConnection",
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision",
    ]
  }
}

module "codepipeline_role" {
  source      = "./module/iam_role"
  name        = "${var.system_name}-${var.env_name}-pipeline-role"
  identifiers = "codepipeline.amazonaws.com"
  policy      = data.aws_iam_policy_document.codepipeline.json
}

resource "aws_s3_bucket" "artifact" {
  bucket = "${var.system_name}-${var.env_name}-pipeline-artifact"
}

resource "aws_codestarconnections_connection" "github-connection" {
  name          = "github-connection"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "pipeline" {
  name     = "${var.system_name}-${var.env_name}-pipeline"
  role_arn = module.codepipeline_role.iam_role_arn

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = 1
      output_artifacts = ["SourceArtifact"]
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github-connection.arn
        FullRepositoryId = "masutaro99/sample-container"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = 1
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      configuration = {
        ProjectName = aws_codebuild_project.build.id
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name      = "Deploy"
      category  = "Deploy"
      owner     = "AWS"
      provider  = "CodeDeployToECS"
      region    = var.aws_region
      run_order = 1
      version   = "1"

      configuration = {
        ApplicationName                = aws_codedeploy_app.ecs_app.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.deployment_group.deployment_group_name
        TaskDefinitionTemplateArtifact = "BuildArtifact"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "SourceArtifact"
        AppSpecTemplatePath            = "appspec.yml"
        Image1ArtifactName             = "BuildArtifact"
        Image1ContainerName            = "IMAGE1_NAME"
      }

      input_artifacts = ["SourceArtifact", "BuildArtifact"]
    }
  }

  artifact_store {
    location = aws_s3_bucket.artifact.id
    type     = "S3"
  }
}
