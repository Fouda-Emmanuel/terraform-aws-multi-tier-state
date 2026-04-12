output "rds_endpoint" {
  description = "RDS Endpoint"
  value = aws_db_instance.my_rds.endpoint
}

output "rabbitmq_endpoint" {
  description = "RabbitMQ Endpoint"
  value       = aws_mq_broker.my_rmq.instances[0].endpoints[0]
}
output "memcache_endpoint" {
  description = "Memcache Endpoint"
  value = aws_elasticache_cluster.my_elasticache.configuration_endpoint
}

