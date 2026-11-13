# ------------------------------------------------------------------ Namespace
resource "kubernetes_namespace_v1" "app" {
  metadata {
    name   = var.namespace
    labels = { "app.kubernetes.io/part-of" = "gestion-formation", "managed-by" = "terraform" }
  }
}

# ------------------------------------------------------------ Configuration
resource "kubernetes_config_map_v1" "config" {
  metadata {
    name      = "formation-config"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }
  data = {
    DEBUG         = "False"
    ALLOWED_HOSTS = "*"
    POSTGRES_DB   = var.postgres_db
    POSTGRES_HOST = "postgres"
    POSTGRES_PORT = "5432"
  }
}

resource "kubernetes_secret_v1" "secret" {
  metadata {
    name      = "formation-secret"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }
  data = {
    SECRET_KEY        = var.secret_key
    POSTGRES_USER     = var.postgres_user
    POSTGRES_PASSWORD = var.postgres_password
  }
}

# ------------------------------------------------------------- PostgreSQL
resource "kubernetes_persistent_volume_claim_v1" "postgres" {
  metadata {
    name      = "postgres-pvc"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources { requests = { storage = "2Gi" } }
  }
  wait_until_bound = false
}

resource "kubernetes_deployment_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = { app = "postgres" }
  }
  spec {
    replicas = 1
    strategy { type = "Recreate" }
    selector { match_labels = { app = "postgres" } }
    template {
      metadata { labels = { app = "postgres" } }
      spec {
        # Le volume hostPath de Minikube est local a un noeud : la base reste sur le control-plane
        node_selector = { "node-role.kubernetes.io/control-plane" = "" }
        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        container {
          name  = "postgres"
          image = "postgres:15"
          port { container_port = 5432 }
          env {
            name = "POSTGRES_DB"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.config.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }
          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.secret.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }
          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.secret.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }
          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }
          readiness_probe {
            exec { command = ["sh", "-c", "pg_isready -U \"$POSTGRES_USER\" -d \"$POSTGRES_DB\""] }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 5
          }
          liveness_probe {
            exec { command = ["sh", "-c", "pg_isready -U \"$POSTGRES_USER\""] }
            initial_delay_seconds = 30
            period_seconds        = 15
            timeout_seconds       = 10
            failure_threshold     = 6
          }
          resources {
            requests = { cpu = "250m", memory = "128Mi" }
            limits   = { cpu = "1000m", memory = "384Mi" }
          }
        }
        volume {
          name = "data"
          persistent_volume_claim { claim_name = kubernetes_persistent_volume_claim_v1.postgres.metadata[0].name }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }
  spec {
    selector = { app = "postgres" }
    port {
      port        = 5432
      target_port = 5432
    }
  }
}

# ------------------------------------------------------- Application web
resource "kubernetes_deployment_v1" "web" {
  metadata {
    name      = "web"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = { app = "web" }
  }
  spec {
    replicas = var.web_min_replicas
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "0"
        max_surge       = "1"
      }
    }
    selector { match_labels = { app = "web" } }
    template {
      metadata { labels = { app = "web" } }
      spec {
        # Repartit les pods sur des noeuds differents (haute disponibilite)
        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                topology_key = "kubernetes.io/hostname"
                label_selector { match_labels = { app = "web" } }
              }
            }
          }
        }
        init_container {
          name    = "wait-for-db"
          image   = "postgres:15"
          command = ["sh", "-c", "until pg_isready -h postgres -p 5432; do echo 'attente de PostgreSQL...'; sleep 2; done"]
        }
        init_container {
          name              = "migrate"
          image             = var.image
          image_pull_policy = "IfNotPresent"
          command           = ["python", "manage.py", "migrate", "--noinput"]
          env_from {
            config_map_ref { name = kubernetes_config_map_v1.config.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret_v1.secret.metadata[0].name }
          }
        }
        container {
          name              = "web"
          image             = var.image
          image_pull_policy = "IfNotPresent"
          port { container_port = 8000 }
          env_from {
            config_map_ref { name = kubernetes_config_map_v1.config.metadata[0].name }
          }
          env_from {
            secret_ref { name = kubernetes_secret_v1.secret.metadata[0].name }
          }
          readiness_probe {
            http_get {
              path = "/admin/login/"
              port = 8000
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
          }
          liveness_probe {
            tcp_socket { port = 8000 }
            initial_delay_seconds = 30
            period_seconds        = 15
            timeout_seconds       = 5
            failure_threshold     = 4
          }
          resources {
            requests = { cpu = "100m", memory = "128Mi" }
            limits   = { cpu = "500m", memory = "384Mi" }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_deployment_v1.postgres, kubernetes_service_v1.postgres]

  timeouts {
    create = "15m"
    update = "15m"
  }

  # le nombre de replicas est pilote par l'HPA apres la creation
  lifecycle {
    ignore_changes = [spec[0].replicas]
  }
}

resource "kubernetes_service_v1" "web" {
  metadata {
    name      = "web"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }
  spec {
    type     = local.cluster.service_type
    selector = { app = "web" }
    port {
      port        = 8000
      target_port = 8000
      node_port   = local.cluster.service_type == "NodePort" ? var.node_port : null
    }
  }
}

# ------------------------------------------------------------ Auto-scaling
resource "kubernetes_horizontal_pod_autoscaler_v2" "web" {
  metadata {
    name      = "web"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }
  spec {
    min_replicas = var.web_min_replicas
    max_replicas = var.web_max_replicas
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.web.metadata[0].name
    }
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
  }
}
