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
}