resource "kubernetes_deployment_v1" "dvwa" {
  depends_on = [
    module.eks
  ]
  metadata {
    name      = "dvwa-container-escape"
    namespace = "default"
  }

  spec {
    selector {
      match_labels = {
        app = "dvwa-container-escape"
      }
    }

    template {
      metadata {
        labels = {
          app = "dvwa-container-escape"
        }
      }

      spec {
        container {
          image             = "public.ecr.aws/x6s5a8t7/dvwa:latest"
          name              = "dvwa"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = "80"
          }
          security_context {
            privileged = true
          }
        }

        termination_grace_period_seconds = 30
      }
    }
  }
}