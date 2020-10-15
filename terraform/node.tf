resource "openstack_compute_floatingip_v2" "fip_node" {
    depends_on  = [openstack_compute_floatingip_associate_v2.fip]
    pool        = var.fip_pool
}

resource "openstack_compute_instance_v2" "node" {
    name            = "node"
    image_id        = var.image_id
    flavor_id       = var.flavor_id
    key_pair        = var.key_pair
    security_groups = ["default"]
}

resource "openstack_compute_floatingip_associate_v2" "fip_node" {
    floating_ip = openstack_compute_floatingip_v2.fip_node.address
    instance_id = openstack_compute_instance_v2.node.id
}

resource "null_resource" "ansible-playbook-node" {

    depends_on  = [openstack_compute_floatingip_associate_v2.fip_node]

    provisioner "remote-exec" {
        inline = [
			"echo 'connected!'",
			]
			  connection {
				  type     = "ssh"
				  user     = var.ssh_usr
				  host     = openstack_compute_floatingip_associate_v2.fip_node.floating_ip
				  agent    = true   
			}
    }

    provisioner "local-exec" {
        command = <<EOT
cat <<EOF > ansible/node-hosts
[nodes]
${openstack_compute_floatingip_associate_v2.fip_node.floating_ip}

[nodes:vars]
ansible_user= ${var.ssh_usr}
EOF
EOT
    }

    provisioner "local-exec" {
        command = "ansible-playbook -i ansible/node-hosts ansible/playbook.yml"
    }
}

resource "null_resource" "join-cluster" {

    depends_on = [null_resource.ansible-playbook]

    provisioner "remote-exec" {
        inline = [
			"set -e",
            "sudo ${data.external.kubeadm-join.result.command}",
			]
			  connection {
				  type     = "ssh"
				  user     = var.ssh_usr
				  host     = openstack_compute_floatingip_associate_v2.fip_node.floating_ip
				  agent    = true   
			}
    }
}

resource "null_resource" "deploy" {

    depends_on = [null_resource.join-cluster]

    provisioner "local-exec" {
        command = <<EOA
        kubectl config use-context ${openstack_compute_instance_v2.master.name}@kubernetes
        helm install msg-srv ../chart/
        EOA
    }
}