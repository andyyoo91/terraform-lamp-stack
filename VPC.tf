provider "aws" {
  #   access_key = ""
  #   secret_key = ""
  region = "us-east-1"
}

resource "aws_vpc" "ay_vpc" {
  cidr_block       = "${var.vpc_cidr}"
  instance_tenancy = "default"

  tags {
    Name = "AyVPC"
  }
}

resource "aws_subnet" "Private_Subnet" {
  vpc_id            = "${aws_vpc.ay_vpc.id}"
  cidr_block        = "${var.private_subnet_cidr}"
  availability_zone = "us-east-1a"

  tags {
    Name = "Ay_Private_Subnet"
  }
}

resource "aws_subnet" "Public_Subnet" {
  vpc_id            = "${aws_vpc.ay_vpc.id}"
  cidr_block        = "${var.public_subnet_cidr}"
  availability_zone = "us-east-1b"

  tags {
    Name = "Ay_Public_Subnet"
  }
}

resource "aws_subnet" "Public_Subnet2" {
  vpc_id            = "${aws_vpc.ay_vpc.id}"
  cidr_block        = "${var.public_subnet2_cidr}"
  availability_zone = "us-east-1c"

  tags {
    Name = "Ay_Public_Subnet2"
  }
}

resource "aws_instance" "AYEC2" {
  ami           = "ami-0080e4c5bc078760e"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.Private_Subnet.id}"

  tags {
    Name = "AYEC2"
  }
}

resource "aws_db_instance" "MySQL" {
  identifier           = "myappdb-rds"
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.6.40"
  instance_class       = "db.t2.micro"
  name                 = "myappdb"
  username             = "Yoo"
  password             = "YooAndy0626"
  parameter_group_name = "default.mysql5.6"
  db_subnet_group_name = "aydb_subnet_group"
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
    nat_gateway_id = "${aws_nat_gateway.NAT.id}"
  }

  tags = {
    Name = "AY_Private_RT"
  }
}

resource "aws_route_table_association" "PR" {
  subnet_id      = "${aws_subnet.Private_Subnet.id}"
  route_table_id = "${aws_route_table.RT_Private_subnet.id}"
}

resource "aws_route_table" "RT_Public_subnet" {
  vpc_id = "${aws_vpc.ay_vpc.id}"
  
  route {
    cidr_block = "${var.route_table_public_cidr}"
    nat_gateway_id = "${aws_nat_gateway.NAT.id}"

  }

  tags = {
    Name = "AY_Public_RT"
  }
}

resource "aws_route_table_association" "PU" {
  subnet_id      = "${aws_subnet.Public_Subnet.id}"
  route_table_id = "${aws_route_table.RT_Public_subnet.id}"
}

resource "aws_security_group" "AY_EC2" {
  name        = "EC2_to_RDS"
  description = "Allowing EC2 instance to communicate with RDS instance"
  vpc_id      = "${aws_vpc.ay_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "AY_EC2_Security_group"
  }
}

resource "aws_security_group" "AY_MYSQL" {
  name        = "web server"
  description = "Allow access to MySQL RDS"
  vpc_id      = "${aws_vpc.ay_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "AY_MYSQL_Security_group"
  }
}

resource "aws_db_subnet_group" "AY-db" {
  name        = "aydb_subnet_group"
  description = "Our main group of subnets"
  subnet_ids  = ["${aws_subnet.Private_Subnet.id}", "${aws_subnet.Public_Subnet2.id}"]
}

resource "aws_lb" "test" {
  name               = "AYtest-alb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.test.id}"]
  subnets            = ["${aws_subnet.Public_Subnet.id}", "${aws_subnet.Public_Subnet2.id}"]

  tags = {
    Environment = "dev"
  }
}

resource "aws_lb_target_group" "ALB_TG" {
  name     = "AWS-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.ay_vpc.id}"
}

resource "aws_lb_target_group_attachment" "ALB_TG_attachment" {
  target_group_arn = "${aws_lb_target_group.ALB_TG.arn}"
  target_id        = "${aws_instance.AYEC2.id}"
  port             = 80
}

resource "aws_security_group" "test" {
  name        = "ALB-SecurityGroup"
  description = "Limiting network only within Plus3IT"
  vpc_id      = "${aws_vpc.ay_vpc.id}"

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["173.10.166.169/32"]
  }

  egress {
    from_port       = "0"
    to_port         = "0"
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = ["${aws_security_group.AY_EC2.id}"]
  }

  tags {
    Name = "AY_ALB_Security_group"
  }
}

resource "aws_lb_listener" "test" {
  load_balancer_arn = "${aws_lb.test.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.ALB_TG.arn}"
  }
}

resource "aws_nat_gateway" "NAT" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.Private_Subnet.id}"
}

resource "aws_eip" "nat" {
  vpc = true

  tags {
    Name = "AY_EIP"
  }
}
