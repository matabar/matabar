output "repository" {
  description = "Full name of the monorepo."
  value       = github_repository.this.full_name
}

output "pages_url" {
  description = "URL GitHub Pages reports for the site."
  value       = github_repository_pages.this.html_url
}

output "pages_cname" {
  description = "Custom domain configured on the Pages site."
  value       = github_repository_pages.this.cname
}

output "production_environment" {
  description = "Environment that gates apply."
  value       = github_repository_environment.deploy.environment
}

output "reviewer" {
  description = "GitHub login required to approve production deployments."
  value       = data.github_user.reviewer.login
}
