resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.system_name}-${var.env_name}-ecs-cluster"
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "sample-container"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./container_definition.json")
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_ecs_service" "ecs_service" {
  name                              = "${var.system_name}-${var.env_name}-ecs-service"
  cluster                           = aws_ecs_cluster.ecs_cluster.arn
  task_definition                   = aws_ecs_task_definition.task_definition.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = true
    security_groups  = [module.task_sg.security_group_id]
    subnets = [
      aws_subnet.public-subnet-1.id,
      aws_subnet.public-subnet-2.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "sample-container"
    container_port   = 80
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

module "task_sg" {
  source      = "./module/security_group"
  name        = "${var.system_name}-${var.env_name}-task-sg"
  vpc_id      = aws_vpc.vpc.id
  port        = 80
  cidr_blocks = [aws_vpc.vpc.cidr_block]
}

resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/ecs/example"
  retention_in_days = 180
}

data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_execution" {
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}

module "ecs_task_execution_role" {
  source      = "./module/iam_role"
  name        = "ecs-task-execution"
  identifiers = "ecs-tasks.amazonaws.com"
  policy      = data.aws_iam_policy_document.ecs_task_execution.json
}