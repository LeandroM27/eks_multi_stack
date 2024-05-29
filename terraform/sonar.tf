data "aws_db_instance" "rds" {
  db_instance_identifier = "${var.project_name}-sonardb-${var.environment}"
}

resource "helm_release" "sonarqube" {
  name       = "${var.project_name}-sonarqube-${var.environment}"
  repository = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart      = "sonarqube"
  version    = "10.0.0+521"

  values = [
    file("${path.module}/sonarqube-values.yml")
  ]


  set {
    name  = "jdbcOverwrite.enable"
    value = true
  }

  set {
    name  = "jdbcOverwrite.jdbcUrl"
    value = "jdbc:postgresql://${data.aws_db_instance.rds.endpoint}/sonardb"
  }

  set {
    name  = "jdbcOverwrite.jdbcUsername"
    value = var.sonar_user
  }

  set {
    name  = "jdbcOverwrite.jdbcPassword"
    value = var.sonar_pass
  }

}