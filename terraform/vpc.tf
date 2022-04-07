data "aws_vpc" "target_Vpc" {
   filter {
     name = "tag:Name"
     values = ["${var.vpc_name}"]
   }
}


data "aws_subnets" "public_subnets" {

filter {
    name   = "vpc-id"
    values = tolist([data.aws_vpc.target_Vpc.id])
  }
  tags = {
    Name = "*public*"
  }
}

data "aws_subnets" "private_subnets" {

filter {
    name   = "vpc-id"
    values = tolist([data.aws_vpc.target_Vpc.id])
  }
  tags = {
    Name = "*private*"
  }
}
