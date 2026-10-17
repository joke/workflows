output "node_id" {
  description = "GraphQL node ID of the repository, used by resources that take a repository_id."
  value       = github_repository.this.node_id
}
