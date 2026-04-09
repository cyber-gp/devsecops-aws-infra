# Website URL
output "website_url" {
  value = "https://${var.record_name}.${var.domain_name}"
}