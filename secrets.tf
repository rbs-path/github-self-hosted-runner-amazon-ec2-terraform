
data "aws_secretsmanager_secret" "github_app" {
  name = var.github_app_secret
}

data "aws_secretsmanager_secret_version" "github_app" {
  secret_id = data.aws_secretsmanager_secret.github_app.id
}
