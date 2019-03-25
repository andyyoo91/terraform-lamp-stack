

provider "aws" {
#   access_key = ""
#   secret_key = ""
  region     = "us-east-1"
}
resource "aws_vpc" "ay_vpc" {
  cidr_block = "${var.vpc_cidr}"
  instance_tenancy = "default"

tags {
    Name = "AyVPC"
}
}
resource "aws_subnet" "Private_Subnet" {
vpc_id = "${aws_vpc.ay_vpc.id}"
cidr_block = "{${var.private_subnet_cidr}}"
availability_zone = "us-east-1"

tags {  
  Name = "Ay_Private_Subnet" 
}
  }

   resource "aws_subnet" "Public_Subnet" {
vpc_id = "${aws_vpc.ay_vpc.id}"
cidr_block = "${var.public_subnet_cidr}"
availability_zone = "us-east-1"

tags {
  Name = "Ay_Public_Subnet"
} 
   }

resource "aws_instance" "AYEC2" {
    ami = "ami-0080e4c5bc078760e"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.Private_Subnet.id}"
    tags {
        Name = "AYEC2"
    }
}

resource "aws_db_instance" "MySQL" {
    identifier = "myappdb-rds"
    allocated_storage = 10
    engine = "mysql"
    engine_version = "5.6.40"
    instance_class = "db.t2.micro"
    name = "myappdb"
    username = "Yoo"
    password = "YooAndy"
    parameter_group_name = "default.mysql5.6"
}

resource "aws_internet_gateway" "gw" {
vpc_id = "${aws_vpc.ay_vpc.id}"

tags = {
Name = "AY_IGW"
}
}

resource "aws_route_table" "RT_Private_subnet" {
vpc_id = "${aws_vpc.ay_vpc.id}"

route {
  cidr_block = "${var.route_table_private_cidr}"
  gateway_id = "${aws_internet_gateway.gw.id}"
}
}

resource "aws_route_table_association" "PR" {
  subnet_id = "${aws_subnet.Private_Subnet.id}"
  route_table_id = "${aws_route_table.RT_Private_subnet.id}"
  
}


resource "aws_route_table" "RT_Public_subnet" {
vpc_id = "${aws_vpc.ay_vpc.id}"

route {
  cidr_block = "${var.route_table_public_cidr}"
  gateway_id = "${aws_internet_gateway.gw.id}"
}

resource "aws_route_table_association" "PU" {
  subnet_id = "${aws_subnet.Public_Subnet.id}"
  route_table_id = "${aws_route_table.RT_Public_subnet.id}"
}


resource "aws_security_group" "AY_MYSQL" {
  name = "web server"
  description = "Allow access to MySQL RDS"
  vpc_id = "${aws_vpc.ay_vpc.id}"

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 1024
      to_port = 65535
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "AY-db" {
    name = "main"
    description = "Our main group of subnets"
    subnet_id = ["${aws_subnet.Private_Subnet.id}"]
    tags {
        Name = "AYTest DB subnet group"
    }
}


resource "aws_lb" "test" {
  name               = "AYtest-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.ALB-test.id}"]
  subnets            = ["${aws_subnet.Public_Subnet.id}"]

  enable_deletion_protection = true

  tags = {
    Environment = "dev"
  }
}

resource "aws_security_group" "ALB-test" {
  name            = "ALB-SecurityGroup"
  description     = "Limiting network only within Plus3IT"
  vpc_id          = "${aws_vpc.ay_vpc.id}"
  
  ingress {
    from_port = "443"
    to_port = "443"
    protocol = "tcp"
    cidr_blocks = ["173.10.166.169"]
  }
  egress { 
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}
 
resource "aws_security_group" "allow_ssh" {
  name = "allow_all"
  description = "Allow inbound SSH traffic from my IP"
  vpc_id = "${aws_vpc.ay_vpc.id}"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["123.123.123.123/32"]
  }

  tags {
    Name = "Allow SSH"
  }
}

resource "aws_security_group" "nat" {
    name = "vpc_nat"
    description = "Allow traffic to pass from the private subnet to the internet"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${var.private_subnet_cidr}"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["${var.private_subnet_cidr}"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    egress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.ay_vpc.id}"

    tags {
        Name = "NATSG"
    }
}
}
