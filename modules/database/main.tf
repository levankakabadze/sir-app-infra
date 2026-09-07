# ==============================================================================
# DB SUBNET GROUP
# ==============================================================================

resource "aws_db_subnet_group" "main" {
    name       = "${var.project}-${var.environment}-db-subnet-group"
    description = "Subnet group for SIR RDS instance"
    subnet_ids = values(var.isolated_subnet_ids)

    tags = {
        Name        = "${var.project}-${var.environment}-db-subnet-group"
    }
}

# ==============================================================================
# RDS POSTGRESQL INSTANCE
# ==============================================================================

resource "aws_db_instance" "main" {
    identifier              = "${var.project}-${var.environment}-postgres"
    engine                  = "postgres"
    engine_version          = "16"
    instance_class          = var.db_instance_class
    allocated_storage       = 20
    storage_type            = "gp2"

    db_name                  = var.db_name
    username                 = var.db_username
    password                 = var.db_password

    db_subnet_group_name     = aws_db_subnet_group.main.name
    vpc_security_group_ids   = [var.db_sg_id]

    publicly_accessible      = false
    multi_az                 = false
    skip_final_snapshot      = true

    tags = {
        Name        = "${var.project}-${var.environment}-postgres"
    }
}