#name of project
variable "name_of_project" {
  description = "name of project"
  type        = string


}

#####################################################################

#template variables
variable "prj_instance_type" {
  description = "instance type"
  type        = string

}

variable "prj_volume_type" {
  description = "volume type"
  type        = string

}
variable "prj_volume_size" {
  description = "volume type"
  type        = number

}

variable "prj_key_name" {
  description = "key name"
  type        = string

}

#vpc variables
variable "vpc_cidr_block" {
  description = "vpc cidr block"
  type        = string

}
variable "prj_all_trafic" {
  description = "all trafic"
  type        = string
  default     = "0.0.0.0/0"

}

variable "prj_http_port" {
  description = "http port"
  type        = number
  default     = 80

}
variable "prj_ssh_port" {
  description = "http port"
  type        = number

}

