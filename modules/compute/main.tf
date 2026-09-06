# ==============================================================================
# DATA SOURCES
# ==============================================================================

data "aws_region" "current" {}


# ==============================================================================
# APPLICATION LOAD BALANCER
# ==============================================================================

resource "aws_lb" "main" {
    name               = "${var.project}-${var.environment}-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [var.alb_sg_id]
    subnets            = values(var.public_subnet_ids)

    tags = {
        Name        = "${var.project}-${var.environment}-alb"
    }
}

resource "aws_lb_target_group" "main" {
    name     = "${var.project}-${var.environment}-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = var.vpc_id

    health_check {
        enabled            = true
        path                = "/"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200"
    }

    tags = {
        Name        = "${var.project}-${var.environment}-tg"
    }
}

resource "aws_lb_listener" "main" {
    load_balancer_arn = aws_lb.main.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.main.arn
    }
}

# ==============================================================================
# EC2 INSTANCE
# ==============================================================================

resource "aws_instance" "main" {
    ami                    = var.ami_id
    instance_type          = var.instance_type
    subnet_id              = var.private_subnet_ids["a"]
    vpc_security_group_ids = [var.app_sg_id]

    user_data = templatefile("${path.module}/user_data.sh", {
        environment = var.environment
        region      = data.aws_region.current.name
    })

    tags = {
        Name        = "${var.project}-${var.environment}-ec2"
    }
}

# ==============================================================================
# TARGET GROUP ATTACHMENT
# ==============================================================================

resource "aws_lb_target_group_attachment" "main" {
    target_group_arn = aws_lb_target_group.main.arn
    target_id        = aws_instance.main.id
    port             = 80
}