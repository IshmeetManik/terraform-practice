resource "aws_vpc" "this" {
  for_each             = var.vpc_parameters
  cidr_block           = each.value.cidr_block
  enable_dns_support   = each.value.enable_dns_support
  enable_dns_hostnames = each.value.enable_dns_hostnames
  tags = merge(each.value.tags, {
    Name : each.key
  })
}

resource "aws_subnet" "this" {
  for_each   = var.subnet_parameters
  vpc_id     = aws_vpc.this[each.value.vpc_name].id
  cidr_block = each.value.cidr_block
  tags = merge(each.value.tags, {
    Name : each.key
  })
}

resource "aws_internet_gateway" "this" {
  for_each = var.igw_parameters
  vpc_id   = aws_vpc.this[each.value.vpc_name].id
  tags = merge(each.value.tags, {
    Name : each.key
  })
}

resource "aws_route_table" "this" {
  for_each = var.rt_parameters
  vpc_id   = aws_vpc.this[each.value.vpc_name].id
  tags = merge(each.value.tags, {
    Name : each.key
  })

  dynamic "route" {
    for_each = each.value.routes
    content {
      cidr_block = route.value.cidr_block
      gateway_id = route.value.use_igw ? aws_internet_gateway.this[route.value.gateway_id].id : route.value.gateway_id
    }
  }
}

resource "aws_route_table_association" "this" {
  for_each       = var.rt_association_parameters
  subnet_id      = aws_subnet.this[each.value.subnet_name].id
  route_table_id = aws_route_table.this[each.value.rt_name].id
}

resource "aws_security_group" "allow_ssh" {
  name_prefix = "allow_ssh"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_iam_role" "ssm_role" {
  name = "ssm_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm_instance_profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "ssm_instance" {
  ami           = "ami-0c55b159cbfafe1f0" # Use the appropriate AMI ID for your region and instance type
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  security_groups = [aws_security_group.allow_ssh.name]
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  tags = {
    Name = "ssm_instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum install -y amazon-ssm-agent
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent
              EOF
}
