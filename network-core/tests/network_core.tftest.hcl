variables {
  region                    = "us-east-1"
  availability_zone         = "us-east-1a"
  number_availability_zones = 2
  vpc_cidr_block            = "10.2.0.0/16"
  origin_repo               = "my-terraform-lab"
}

run "basic" {
  command = apply

  assert {
    condition     = output.aws_vpc_id != ""
    error_message = "VPC ID should not be empty"
  }

  assert {
    condition     = output.aws_vpc_ipv4_cidr_block == "10.2.0.0/16"
    error_message = "VPC CIDR block should match input value"
  }

  assert {
    condition     = length(output.aws_subnets_public) == 2
    error_message = "Should create 2 public subnets"
  }

  assert {
    condition     = length(output.aws_subnets_private) == 2
    error_message = "Should create 2 private subnets"
  }

  assert {
    condition     = output.aws_igw_id != ""
    error_message = "Internet Gateway ID should not be empty"
  }
}
