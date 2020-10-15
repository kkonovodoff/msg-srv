resource "openstack_compute_floatingip_v2" "fip" {
    pool    = var.fip_pool
}

resource "openstack_compute_instance_v2" "master" {
    name            = "k8s_master"
    image_id        = var.image_id
    flavor_id       = var.flavor_id
    key_pair        = var.key_pair
    security_groups = ["default"]
}

resource "openstack_compute_floatingip_associate_v2" "fip" {
    floating_ip = openstack_compute_floatingip_v2.fip.address
    instance_id = openstack_compute_instance_v2.master.id
}

resource "null_resource" "ansible-playbook" {

    depends_on  = [openstack_compute_floatingip_associate_v2.fip]

    provisioner "remote-exec" {
        inline = [
			"echo 'connected!'",
			]
			  connection {
				  type     = "ssh"
				  user     = var.ssh_usr
				  host     =  openstack_compute_floatingip_associate_v2.fip.floating_ip
				  agent    = true   
			}
    }

    provisioner "local-exec" {
        command = <<EOT
cat <<EOF > ansible/master-hosts
[master]
${openstack_compute_floatingip_associate_v2.fip.floating_ip}

[master:vars]
ansible_user= ${var.ssh_usr}
EOF
EOT
    }

    provisioner "local-exec" {
        command = "ansible-playbook -i ansible/master-hosts ansible/playbook.yml"
    }
}

resource "null_resource" "k8s-init" {

    depends_on  = [null_resource.ansible-playbook]

    provisioner "remote-exec" {
        inline = [
			"sudo kubeadm init --pod-network-cidr=${var.pod_net_cidr}  --apiserver-cert-extra-sans=${openstack_compute_floatingip_associate_v2.fip.floating_ip}",
            "mkdir -p $HOME/.kube",
            "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
            "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
            "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml",
			]
			  connection {
				  type     = "ssh"
				  user     = var.ssh_usr
				  host     = openstack_compute_floatingip_associate_v2.fip.floating_ip
				  agent    = true   
			}
    }

    provisioner "local-exec" {
        command = <<EOX
            cd scripts
            scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${var.ssh_usr}@${openstack_compute_floatingip_associate_v2.fip.floating_ip}:~/.kube/config .
            python process_yaml.py ${openstack_compute_floatingip_associate_v2.fip.floating_ip} ${openstack_compute_instance_v2.master.name}
            KUBECONFIG=~/.kube/config:./config kubectl config view --flatten > ~/.kube/config_new
            mkdir ~/.kube/old/
            mv ~/.kube/config ~/.kube/old/
            mv ~/.kube/config_new ~/.kube/config
            rm config
        EOX
    }
}

data "external" "kubeadm-join" {

    depends_on  = [null_resource.k8s-init]

    program     = ["./scripts/kubeadm-token.sh"]

    query = {
        host    = openstack_compute_floatingip_associate_v2.fip.floating_ip
        usr     = var.ssh_usr
    }
}