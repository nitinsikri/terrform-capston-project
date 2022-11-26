provider "aws" {
  profile = "demo"
  region ="us-east-1"
}

resource "aws_vpc" "demo-vpc" {
    cidr_block = "10.0.0.0/16"
  
}

resource "aws_subnet" "public-subnet" {
  vpc_id     = "${aws_vpc.demo-vpc.id}"
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "public-subnet2" {
  vpc_id     = "${aws_vpc.demo-vpc.id}"
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "public-subnet2"
  }
}

resource "aws_internet_gateway" "vpc-igw" {
    vpc_id = "${aws_vpc.demo-vpc.id}"

    tags = {
      "Name" = "vpc-igw"
    }

 }

resource "aws_network_acl" "public-nacl" {
    vpc_id = "${aws_vpc.demo-vpc.id}"
    subnet_ids = ["${aws_subnet.public-subnet.id}","${aws_subnet.public-subnet2.id}"]

    egress  {
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = "80"
        protocol = "tcp"
        rule_no = "100"
        to_port = "80"
        } 

    ingress {
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = "80"
        to_port = "80"
        rule_no = "100"
        protocol = "tcp"
    }

     ingress {
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = "1024"
        to_port = "65535"
        rule_no = "200"
        protocol = "tcp"
    }

    egress {
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = "1024"
        to_port = "65535"
        rule_no = "200"
        protocol = "tcp"
    }

    ingress {
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = "22"
        to_port = "22"
        rule_no = "300"
        protocol = "tcp"
    }

    egress  {
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = "22"
        protocol = "tcp"
        rule_no = "300"
        to_port = "22"
        } 
}

resource "aws_security_group" "webserver-sg" {
    name = "WebDMZ"
    description = "Security group of my web server"
    vpc_id = "${aws_vpc.demo-vpc.id}"

    ingress {
        from_port = "80"
        to_port = "80"
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "TCP"
    }
}
resource "aws_security_group" "lb-sg" {
    name = "LoadBalancer-SG"
    description = "Security group of my ALB"
    vpc_id = "${aws_vpc.demo-vpc.id}"

    ingress {
        from_port = "22"
        to_port = "22"
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "TCP"
    }
}



resource "aws_security_group" "db-sg" {
    name = "Mysql-SG"
    description = "Security group of my MYSQL RDS instance"
    vpc_id = "${aws_vpc.demo-vpc.id}"

    ingress {
        from_port = "3306"
        to_port = "3306"
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "TCP"
    }
}

resource "aws_instance" "webserver1" {
    ami = "ami-0b0dcb5067f052a63"
    instance_type = "t2.micro"
    vpc_security_group_ids =  ["${aws_security_group.webserver-sg.id}"]
    key_name = "Demokey"
    user_data = "${file("script.sh")}"
    subnet_id = "${ aws_subnet.public-subnet.id}"
}

resource "aws_instance" "webserver2" {
    ami = "ami-0b0dcb5067f052a63"
    instance_type = "t2.micro"
    vpc_security_group_ids =  ["${aws_security_group.webserver-sg.id}"]
    key_name = "Demokey"
    user_data = "${file("script2.sh")}"
    subnet_id = "${ aws_subnet.public-subnet2.id}"
}

resource "aws_lb" "web-lb" {
  name = "web-lb"
  load_balancer_type = "application"
  internal = "false"
  subnets = ["${ aws_subnet.public-subnet.id}","${ aws_subnet.public-subnet2.id}"]
  security_groups = ["${aws_security_group.lb-sg.id}"]

   }
resource "aws_lb_listener" "web-lb-listener" {
    load_balancer_arn =  "${aws_lb.web-lb.id}"
    port = "80"
    protocol = "HTTP"
    default_action {
        type = "forward"
        target_group_arn = "${aws_lb_target_group.web-tg.id}"
    }
}

resource "aws_lb_target_group" "web-tg" {
  name = "web-tg"
  port = "80"
  protocol ="HTTP"
  vpc_id = "${aws_vpc.demo-vpc.id}"
}

resource "aws_lb_target_group_attachment" "web-tg-attach" {
    target_group_arn = "${aws_lb_target_group.web-tg.arn}"
    target_id = "${aws_instance.webserver1.id}"
    port ="80"
}

resource "aws_lb_target_group_attachment" "web-tg-attach2" {
    target_group_arn = "${aws_lb_target_group.web-tg.arn}"
    target_id = "${aws_instance.webserver2.id}"
    port ="80"
}

resource "aws_db_instance" "mysql-db" {
  allocated_storage    = "20"
  storage_type         = "gp2"
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7.33"
  instance_class       = "db.t3.micro"
  username             = "mysqluser"
  password             = "mysqlpassword"
  skip_final_snapshot  = true
  db_subnet_group_name = "${aws_db_subnet_group.mysql-subnet-group.id}"
  vpc_security_group_ids = ["${aws_security_group.db-sg.id}"]
}

resource "aws_db_subnet_group" "mysql-subnet-group" {
    name = "mysql-subnet-group"
    subnet_ids = ["${ aws_subnet.public-subnet.id}","${ aws_subnet.public-subnet2.id}"]
     
}