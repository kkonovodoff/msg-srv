variable "user_name" {
    type        = string
    description = "Username used to auth in OpenStack"
}

variable "tenant_name" {
    type        = string
    description = "Tenant name for OpenStack"
}

variable "password" {
    type        = string
    description = "Password used to auth in OpenStack"
}

variable "auth_url" {
    type        = string
    description = "OpenStack's url"
}

variable "image_id" {
    type        = string
    description = "Image ID for OpenStack"
}

variable "flavor_id" {
    type        = string
    description = "Flavor ID for OpenStack"
}

variable "key_pair" {
    type        = string
    description = "Key pair for ssh access"
}

variable "ssh_usr" {
    type        = string
    description = "Ssh user name"
}

variable "ssh_key" {
    type        = string
    description = "Path to your private key"
    default     = "~/.ssh/id_rsa"
}

variable "fip_pool" {
    type        = string
    description = "Floating ip pool's name"
    default     = "Public Floating"
}

variable "pod_net_cidr" {
    type        = string
    description = "Pod CIDR for kubeadm init (currently using flannel)"
    default     = "10.244.0.0/16"
}