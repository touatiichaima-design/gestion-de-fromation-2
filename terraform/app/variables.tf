variable "cluster_state_path" {
  description = "Etat Terraform du cluster cible (../infra en local, ../azure pour AKS)"
  type        = string
  default     = "../infra/terraform.tfstate"
}

variable "namespace" {
  type    = string
  default = "formation"
}

variable "image" {
  description = "Image Docker de l'application (produite par le pipeline CI/CD)"
  type        = string
  default     = "chaimatouati/gestion-formation:latest"
}

variable "web_min_replicas" {
  type    = number
  default = 2
}

variable "web_max_replicas" {
  type    = number
  default = 4
}

variable "node_port" {
  type    = number
  default = 30080
}

# ---- Secrets : jamais dans le code, fournis par TF_VAR_* (voir scripts/tf-apply.sh) ----
variable "secret_key" {
  type      = string
  sensitive = true
}

variable "postgres_user" {
  type    = string
  default = "formation_user"
}

variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "postgres_db" {
  type    = string
  default = "formation_db"
}
