provider "aws" {
  region = "us-east-1"

}

module "aws_lb_as_ec2" {
  source            = "./module/vpc_ec2_lb_as"
  name_of_project   = "Project"
  prj_instance_type = "t2.micro"
  prj_volume_type   = "gp2"
  prj_volume_size   = 15
  prj_key_name      = "next"
  prj_ssh_port      = 22
  vpc_cidr_block    = "10.0.0.0/24"


}
