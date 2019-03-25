variable "vpc_cidr" {
default = "190.160.0.0/16"

}

variable "private_subnet_cidr" {
default = "190.160.1.0/24"

}

variable "public_subnet_cidr" {
default = "190.160.2.0/24"

}

variable "route_table_private_cidr" {
    default = "0.0.0.0/0"
}

variable "route_table_public_cidr" {
    default = "0.0.0.0/0"
}
