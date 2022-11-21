    provider "aws" {
        profile ="${var.profile}"
        region="${var.region}"
    }

    resource "aws_instance" "demo-instance" {
        ami ="${lookup(var.amis,var.region)}"
        instance_type ="t2.micro"
        
        tags ={
            Name: "Demoinstance"
        }
    
    }   