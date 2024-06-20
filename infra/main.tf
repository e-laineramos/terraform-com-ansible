terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.43.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = var.region_aws
}

resource "aws_launch_template" "maquina" {
  image_id      = "ami-080e1f13689e07408"
  instance_type = var.instance
  key_name      = var.chave

  tags = {
    Name  = "App Server"
    Owner = "Elaine Ramos"
  }
  security_group_names = [var.grupoDeSeguranca]
  user_data            = var.producao ? filebase64("ansible.sh") : ""
}

resource "aws_key_pair" "chaveSSH" {
  key_name   = var.chave
  public_key = file("${var.chave}.pub")

}


resource "aws_autoscaling_group" "grupo" {
  availability_zones = ["${var.region_aws}a", "${var.region_aws}b"]
  name               = var.asgroup
  max_size           = var.maximo
  min_size           = var.minimo
  launch_template {
    id      = aws_launch_template.maquina.id
    version = "$Latest"
  }
  target_group_arns = var.producao ? [aws_lb_target_group.alvoLoadBalancer[0].arn] : []
}

resource "aws_default_subnet" "subnet_1" {
  availability_zone = "${var.region_aws}a"
}

resource "aws_default_subnet" "subnet_2" {
  availability_zone = "${var.region_aws}b"
}

resource "aws_lb" "loadBalancer" {
  internal = false
  subnets  = [aws_default_subnet.subnet_1.id, aws_default_subnet.subnet_2.id]
  count    = var.producao ? 1 : 0
}

resource "aws_default_vpc" "vpc" {
}

resource "aws_lb_target_group" "alvoLoadBalancer" {
  name     = "alvoLoadBalancer"
  port     = "8000"
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.vpc.id
  count    = var.producao ? 1 : 0
}

resource "aws_lb_listener" "entradaLoadBalancer" {
  load_balancer_arn = aws_lb.loadBalancer[0].arn
  port              = "8000"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alvoLoadBalancer[0].arn
  }
  count = var.producao ? 1 : 0
}

resource "aws_autoscaling_policy" "escala-Producao" {
  name                   = "terraform-escala"
  autoscaling_group_name = var.asgroup
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}