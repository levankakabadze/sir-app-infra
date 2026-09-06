# ==============================================================================
# SECURITY GROUPS — created empty first to avoid circular dependencies
# ==============================================================================

resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}-${var.environment}-alb-sg"
  }
}

resource "aws_security_group" "app" {
  name        = "${var.project}-${var.environment}-app-sg"
  description = "Security group for the application EC2 server"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}-${var.environment}-app-sg"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.project}-${var.environment}-db-sg"
  description = "Security group for the RDS PostgreSQL database"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}-${var.environment}-db-sg"
  }
}

# ==============================================================================
# ALB SECURITY GROUP RULES
# ==============================================================================

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  description       = "HTTP from internet"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  description       = "HTTPS from internet"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_egress_app" {
  type                     = "egress"
  description              = "HTTP to app tier"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.alb.id
}

# ==============================================================================
# APP SECURITY GROUP RULES
# ==============================================================================

resource "aws_security_group_rule" "app_ingress_alb" {
  type                     = "ingress"
  description              = "HTTP from ALB only"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_egress_db" {
  type                     = "egress"
  description              = "PostgreSQL to database tier"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db.id
  security_group_id        = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_egress_internet" {
  type              = "egress"
  description       = "HTTPS to internet for OS patching via NAT"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
}

# ==============================================================================
# DB SECURITY GROUP RULES
# ==============================================================================

resource "aws_security_group_rule" "db_ingress_app" {
  type                     = "ingress"
  description              = "PostgreSQL from app tier only"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.db.id
}