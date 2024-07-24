output "vpcs" {
  description = "VPC Outputs"
  value       = { for vpc in aws_vpc.this : vpc.tags.Name => { "cidr_block" : vpc.cidr_block, "id" : vpc.id } }
}
output "instance_id" {
  value = aws_instance.ssm_instance.id
}

output "instance_public_ip" {
  value = aws_instance.ssm_instance.public_ip
}
