output "target_Vpc" {
  value       = data.aws_vpc.target_Vpc
}

output "public_subnets" {
  value       = data.aws_subnets.public_subnets
}

output "private_subnets" {
  value       = data.aws_subnets.private_subnets
}


output "consule_server" {
  value = aws_instance.consul_server[*].public_ip
}

output "consule_agent" {
  value = aws_instance.consul_agent[*].public_ip
}