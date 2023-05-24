output "cluster_name" {
  value = aws_eks_cluster.cloud-demo.name
}
output "cluster_endpoint" {
  value = aws_eks_cluster.cloud-demo.endpoint
}
output "cluster_ca_certificate" {
  value = aws_eks_cluster.cloud-demo.certificate_authority[0].data
}
output "region" {
  description = "AWS region"
  value       = var.region
}
output "subnets" {
  description = "AWS Subnets"
  value = aws_subnet.public
}
output "vip-eip" { 
  description = "AWS vThunder VIP IP"
  value = aws_eip.vthunder-vip
}
output "vth-mgmt-eip" {
  description = "AWS vThunder Management IP - Public"
  value = aws_eip.mgmt1
}
output "vth-instanceid" { 
  description = "AWS vThunder Instance ID"
  value = "${element(aws_instance.vthunder.*.id, 0)}"
}