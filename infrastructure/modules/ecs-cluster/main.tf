resource "aws_ecs_cluster" "app" {
  name = "${var.project}-cluster"
}
