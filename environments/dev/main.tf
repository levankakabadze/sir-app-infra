# ==============================================================================
# NETWORKING
# ==============================================================================

module "networking" {
  source = "../../modules/networking"

  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr


  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  isolated_subnet_cidrs = var.isolated_subnet_cidrs
  nat_gateway_azs = var.nat_gateway_azs
}

# ==============================================================================
# SECURITY
# ==============================================================================
module "security" {
  source = "../../modules/security"

  project     = var.project
  environment = var.environment
  vpc_id      = module.networking.vpc_id
}

# ==============================================================================
# COMPUTE
# ==============================================================================

module "compute" {
  source = "../../modules/compute"

  project     = var.project
  environment = var.environment
  vpc_id      = module.networking.vpc_id

  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids

  alb_sg_id = module.security.alb_sg_id
  app_sg_id = module.security.app_sg_id

  instance_type = var.instance_type
  ami_id        = var.ami_id
  instance_profile_name = module.iam.ec2_instance_profile_name
}

# ==============================================================================
# DATABASE
# ==============================================================================

module "database" {
  source = "../../modules/database"

  project     = var.project
  environment = var.environment

  isolated_subnet_ids = module.networking.isolated_subnet_ids
  db_sg_id            = module.security.db_sg_id

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  db_instance_class = var.db_instance_class
}

# ==============================================================================
# IAM
# ==============================================================================

module "iam" {
  source = "../../modules/iam"

  project     = var.project
  environment = var.environment
}

# ==============================================================================
# STORAGE
# ==============================================================================

module "storage" {
  source = "../../modules/storage"

  project      = var.project
  environment  = var.environment
  ec2_role_arn = module.iam.ec2_role_arn
}