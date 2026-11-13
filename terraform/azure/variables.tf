variable "project" {
  type    = string
  default = "gestion-formation"
}

variable "location" {
  description = "Region Azure (proche de la Tunisie)"
  type        = string
  default     = "francecentral"
}

variable "vm_size" {
  description = "Taille des VM des noeuds (2 vCPU, 4 Go : economique)"
  type        = string
  default     = "Standard_B2s"
}

variable "min_nodes" {
  type    = number
  default = 2
}

variable "max_nodes" {
  type    = number
  default = 4
}
