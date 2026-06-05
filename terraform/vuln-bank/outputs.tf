output "website_url" {
  description = "HTTPS URL for the application"
  value       = "https://${var.record_name}.${var.domain_name}"
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "ec2_instance_id" {
  value = aws_instance.app.id
}

output "route53_nameservers" {
  description = "Delegate these NS records at your domain registrar"
  value       = aws_route53_zone.main.name_servers
}

output "hosted_zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "app_secret_arn" {
  value = aws_secretsmanager_secret.app.arn
}

output "ssm_instance_id_parameter" {
  value = aws_ssm_parameter.ec2_instance_id.name
}

output "github_deploy_role_arn" {
  description = "Set as GitHub variable VULNBANK_AWS_ROLE_ARN"
  value       = var.github_oidc_enabled ? aws_iam_role.github_deploy[0].arn : null
}
