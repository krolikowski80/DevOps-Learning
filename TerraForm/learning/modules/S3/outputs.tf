output "website_url" {
  description = "URL of the static website"
  value       = aws_s3_bucket_website_configuration.static_sitee_config.website_endpoint
}
