provider "aws" {
    profile ="demo"
    region = "us-east-1"
  
}

resource "aws_vpc" "demo_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
    vpc_id = "${aws_vpc.demo_vpc.id}"
    cidr_block = "10.0.1.0/24"
    
    tags = {
        Name = "public_subnet"
    }
  }

resource "aws_subnet" "public_subnet2" {
    vpc_id = "${aws_vpc.demo_vpc.id}"
    cidr_block = "10.0.2.0/24"
    
    tags = {
        Name = "public_subnet2"
    }
  }


resource "aws_internet_gateway" "vpc-igw" {
    vpc_id = "${aws_vpc.demo_vpc.id}"
  
}

resource "aws_network_acl" "public_nacl" {
     vpc_id = "${aws_vpc.demo_vpc.id}"
     subnet_ids =  ["${aws_subnet.public_subnet.id}","${aws_subnet.public_subnet2.id}"]

    ingress {
        rule_no = "100"
        protocol = "tcp"
        from_port = "80"
        to_port = "80"
        action = "allow"
        cidr_block = "0.0.0.0/0"
     }
    ingress {
        rule_no = "200"
        protocol = "tcp"
        from_port = "1024"
        to_port = "65535"
        action = "allow"
        cidr_block = "0.0.0.0/0"
     }
    
    ingress {
        rule_no = "300"
        protocol = "tcp"
        from_port = "22"
        to_port = "22"
        action = "allow"
        cidr_block = "0.0.0.0/0"
     }
    
    egress {
        rule_no = "100"
        protocol = "tcp"
        from_port = "80"
        to_port = "80"
        action ="allow"
        cidr_block = "0.0.0.0/0"
     }

    egress  {
       action = "allow"
       cidr_block = "0.0.0.0/0"
       from_port = "1024"
       protocol = "tcp"
       rule_no = "200"
       to_port = "65535"
     }

    egress {
        rule_no = "300"
        protocol = "tcp"
        from_port = "22"
        to_port = "22"
        action = "allow"
        cidr_block = "0.0.0.0/0"

    }
}

resource "aws_security_group" "webserver-sg" {
    name = "websDMZ"
    description = "security group of myweb server"
    vpc_id      = "${aws_vpc.demo_vpc.id}"

    ingress {
        from_port = "80"
        to_port = "80"
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }

     ingress {
        from_port = "22"
        to_port = "22"
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }
  
}


resource "aws_security_group" "lb-sg" {
    name = "LoadBalancerSG"
    description = "security group for my ALB"
    ingress {
        from_port = "80"
        to_port = "80"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }
    
    egress {
        from_port = "80"
        to_port = "80"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
       }
    }

resource "aws_instance" "webserver1" {
    ami = "ami-02b972fec07f1e659"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.webserver-sg.id}"]
    key_name = "DemoKeyPair"
    user_data = "${file("script.sh")}"
    subnet_id = "${aws_subnet.public_subnet.id}"
  
}

resource "aws_instance" "webserver2" {
    ami = "ami-02b972fec07f1e659"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.webserver-sg.id}"]
    key_name = "DemoKeyPair"
    user_data = "${file("script2.sh")}"
    subnet_id = "${aws_subnet.public_subnet2.id}"
}

resource "aws_lb" "web-lb" {

    name = "web-lb"  
    load_balancer_type = "application"
    internal = "false"
    subnets = ["${aws_subnet.public_subnet.id}","${aws_subnet.public_subnet2.id}"]
    security_groups = ["${aws_security_group.lb-sg.id}"]

}

resource "aws_lb_listener" "web-lb-listener" {
    load_balancer_arn = "${aws_lb.web-lb.id}"
    port = "80"
    protocol = "http"
    default_action {
      type ="forward"
      target_group_arn ="${aws_lb_target_group.web-tg.id}"
      }
    }

resource "aws_lb_target_group" "web-tg" {
    name = "web-tg"
    port = "80"
    protocol = "tcp"
    vpc_id = "${aws_vpc.demo_vpc.id}"
  }

resource "aws_lb_target_group_attachment" "web-tg-attach1" {

    target_group_arn = "${aws_lb_target_group.web-tg.arn}"
    target_id = "${aws_instance.webserver1.id}"
    port = "80"
  
}

resource "aws_lb_target_group_attachment" "web-tg-attach2" {

    target_group_arn = "${aws_lb_target_group.web-tg.arn}"
    target_id = "${aws_instance.webserver2.id}"
    port = "80"
 }

resource "aws_db_subnet_group" "mysql-sunet-group" {
    name = "mysql-subnet-group"
    subnet_ids = ["${aws_subnet.public_subnet.id}", "${aws_subnet.public_subnet2.id}"]
  
}

resource "aws_security_group" "db-sg" {
    name = "MYSQLSG"
    description = " Security group for db"
    ingress {
        from_port = "3306"
        to_port = "3306"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

 resource "aws_db_instance" "mysqldb" {

    allocated_storage = "20"
    storage_type = "gp2"
    engine = "mysql"
    engine_version = "8.0.23"
    instance_class = "db.t3.micro"
    db_name = "mysqldb"
    username = "mysql-user"
    password = "mysql-password"
    skip_final_snapshot = "true"
    db_subnet_group_name = "${aws_db_subnet_group.mysql-sunet-group.id}"
    vpc_security_group_ids = "${aws_security_group.db-sg.id}"

 }