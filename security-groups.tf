# Bastion Host SG
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Bastion host sg"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name    = "bastion-sg"
    Project = var.proj_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_from_ip" {
  security_group_id = aws_security_group.bastion_sg.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  cidr_ipv4         = var.myip
}

resource "aws_vpc_security_group_egress_rule" "bastion_all_traffic_ipv4" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Application Load Balancer SG
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Application load balancer sg"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name    = "alb-sg"
    Project = var.proj_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_allow_http_ipv4" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_allow_https_ipv4" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "alb_allow_http_ipv6" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv6         = "::/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_allow_https_ipv6" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv6         = "::/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_all_traffic_ipv4" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "alb_traffic_ipv6" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}

# Beanstalk SG 
resource "aws_security_group" "ebs_sg" {
  name        = "ebs-sg"
  description = "Elastic Beanstalk sg"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name    = "ebs-sg"
    Project = var.proj_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "ebs_allow_from_alb" {
  security_group_id            = aws_security_group.ebs_sg.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
  referenced_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh_from_bastion" {
  security_group_id            = aws_security_group.ebs_sg.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_vpc_security_group_egress_rule" "ebs_all_traffic_ipv4" {
  security_group_id = aws_security_group.ebs_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "ebs_traffic_ipv6" {
  security_group_id = aws_security_group.ebs_sg.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}

# Backend SG
resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Backend sg"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name    = "backend-sg"
    Project = var.proj_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_ebs" {
  security_group_id            = aws_security_group.backend_sg.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.ebs_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_bastion" {
  security_group_id            = aws_security_group.backend_sg.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "memcache_from_ebs" {
  security_group_id            = aws_security_group.backend_sg.id
  from_port                    = 11211
  ip_protocol                  = "tcp"
  to_port                      = 11211
  referenced_security_group_id = aws_security_group.ebs_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "rmq_from_ebs" {
  security_group_id            = aws_security_group.backend_sg.id
  from_port                    = 5672
  ip_protocol                  = "tcp"
  to_port                      = 5672
  referenced_security_group_id = aws_security_group.ebs_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "backend_from_itself" {
  security_group_id            = aws_security_group.backend_sg.id
  from_port                    = 0
  ip_protocol                  = "tcp"
  to_port                      = 65535
  referenced_security_group_id = aws_security_group.backend_sg.id
}
