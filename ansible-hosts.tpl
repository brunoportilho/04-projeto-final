[web]
${web}

[all:vars]
ansible_user=${username}
ansible_ssh_private_key_file=./private_key.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=no'