output "infra_repository" {
  description = "Full name of the infrastructure repository."
  value       = github_repository.infra.full_name
}

output "landing_repository" {
  description = "Full name of the public landing repository."
  value       = github_repository.landing.full_name
}

output "landing_pages_url" {
  description = "URL GitHub Pages reports for the landing site."
  value       = github_repository_pages.landing.html_url
}

output "landing_pages_cname" {
  description = "Custom domain configured on the landing Pages site."
  value       = github_repository_pages.landing.cname
}

output "production_environment" {
  description = "Environment that gates apply."
  value       = github_repository_environment.production.environment
}

output "reviewer" {
  description = "GitHub login required to approve production deployments."
  value       = data.github_user.reviewer.login
}
