provider "aws" {
    profile = "${var.profile}"
    region = "${var.region}"
  
}
resource "aws_instance" "demo_instance" {
  ami="ami-08c40ec9ead489470"
  instance_type = "t2.micro"
  key_name = "dockertest.pem"
}