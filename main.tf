/*====
Variables used across all modules
======*/
locals {
  production_availability_zones = ["us-east-1a", "us-east-1b"]
}

provider "aws" {
  region  = "${var.region}"
  profile = "lab"
}

terraform {
  backend "s3" {
    bucket         = "tfstate-tcfiap-queue"
    key            = "terraform.tfstate"
    region         = "us-east-1"
  }
}

module "networking" {
  source               = "./modules/networking"
  prefix          = "queue"
  vpc_cidr             = "10.0.0.0/16"
  public_subnets_cidr  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets_cidr = ["10.0.10.0/24", "10.0.20.0/24"]
  region               = "${var.region}"
  availability_zones   = "${local.production_availability_zones}"
  key_name             = "production_key"
}

module dynamo {
  source = "./modules/dynamo"
}


module "ecs" {
  source              = "./modules/ecs"
  prefix              = "queue"
  vpc_id              = "${module.networking.vpc_id}"
  availability_zones  = "${local.production_availability_zones}"
  repository_name     = "queue/production"
  subnets_ids         = module.networking.private_subnets_id
  public_subnet_ids   = module.networking.public_subnets_id
  security_groups_ids = [
    module.networking.security_groups_ids
  ]
  session_token_aws   = "${var.session_token_aws}"
  access_key_aws      = "${var.access_key_aws}"
  secret_aws          = "${var.secret_aws}"
  execution_arn_role  = "${var.lab_role_arn}"
  depends_on = [
    module.dynamo,
    module.networking
  ]
}
