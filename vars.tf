variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "private_subnet_cidr" {
  default = "10.0.8.0/24"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "public_subnet2_cidr" {
  default = "10.0.3.0/24"
}

variable "route_table_private_cidr" {
  default = "0.0.0.0/0"
}

variable "route_table_public_cidr" {
  default = "0.0.0.0/0"
}
