# RDS resource
resource "aws_db_subnet_group" "my_rds_subgrp" {
  name       = "multi-tier-rds-subgrp"
  subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]

  tags = {
    Name    = "multi-tier-rds-subgrp"
    Project = var.proj_name
  }
}

resource "aws_db_instance" "my_rds" {
  allocated_storage      = 20
  db_name                = var.dbname
  engine                 = "mysql"
  storage_type           = "gp3"
  engine_version         = "8.4.8"
  instance_class         = "db.t4g.micro"
  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true
  username               = var.dbuser
  password               = var.dbpass
  parameter_group_name   = "default.mysql8.4"
  db_subnet_group_name   = aws_db_subnet_group.my_rds_subgrp.name
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
}

# ElastiCache
resource "aws_elasticache_subnet_group" "my_ec_subgrp" {
  name       = "multi-tier-elasticache-subgrp"
  subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]

  tags = {
    Name    = "multi-tier-elasticache-subgrp"
    Project = var.proj_name
  }
}

resource "aws_elasticache_cluster" "my_elasticache" {
  cluster_id           = "multi-tier-elasticache"
  engine               = "memcached"
  engine_version       = "1.6.22"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.memcached1.6"
  port                 = 11211
  security_group_ids   = [aws_security_group.backend_sg.id]
  subnet_group_name    = aws_elasticache_subnet_group.my_ec_subgrp.name

}

# Amazon MQ (RabbitMQ)

resource "aws_mq_broker" "my_rmq" {
  broker_name = "multi-tier-rabbitmq"

  engine_type                = "RabbitMQ"
  engine_version             = "4.2"
  host_instance_type         = "mq.m7g.medium"
  auto_minor_version_upgrade = true
  subnet_ids                 = [module.vpc.private_subnets[0]]
  security_groups            = [aws_security_group.backend_sg.id]

  user {
    username = var.rmquser
    password = var.rmqpass
  }
}
