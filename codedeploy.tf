data "aws_iam_policy_document" "codedeploy" {
  source_json = data.aws_iam_policy.codedeploy.policy
}

data "aws_iam_policy" "codedeploy" {
  arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

module "codedeploy_role" {
  source      = "./module/iam_role"
  name        = "${var.system_name}-${var.env_name}-deploy-role"
  identifiers = "codedeploy.amazonaws.com"
  policy      = data.aws_iam_policy_document.codedeploy.json
}

resource "aws_codedeploy_app" "ecs_app" {
  compute_platform = "ECS"
  name             = "${var.system_name}-${var.env_name}-ecs-app"
}

resource "aws_codedeploy_deployment_group" "deployment_group" {
  depends_on = [
    aws_ecr_repository.repository,
    aws_ecs_cluster.ecs_cluster,
  ]

  app_name               = aws_codedeploy_app.ecs_app.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  #deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"
  deployment_group_name = "${var.system_name}-${var.env_name}-deployment-group"
  service_role_arn      = module.codedeploy_role.iam_role_arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      //action_on_timeout = "CONTINUE_DEPLOYMENT"
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 5
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 0
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.ecs_cluster.name
    service_name = aws_ecs_service.ecs_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.http.arn]
      }

      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }

      test_traffic_route {
        listener_arns = [aws_lb_listener.test_http.arn]
      }

    }

  }

}