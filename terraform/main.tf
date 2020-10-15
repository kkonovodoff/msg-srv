terraform {
    required_version = ">= 0.12.0"

    required_providers {
        openstack = {
            source  = "terraform-provider-openstack/openstack"
            version = "1.32.0"
        }
    }
}

provider "openstack" {
    user_name   = var.user_name
    tenant_name = var.tenant_name
    password    = var.password
    domain_name = "Default"
    auth_url    = var.auth_url
}