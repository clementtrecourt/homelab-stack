[all:vars]
ansible_user=devops
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_become_password=${root_password}

[utility_hosts]
%{ for name, data in containers ~}
%{ if strcontains(name, "k3s") == false ~}
${name} ansible_host=${data.ip} vmid=${data.vmid} ansible_user=root
%{ endif ~}
%{ endfor ~}

[k3s_master]
k3s-master ansible_host=${containers["k3s-master"].ip} vmid=${containers["k3s-master"].vmid}

[k3s_workers]
%{ for name, data in containers ~}
%{ if strcontains(name, "worker") ~}
${name} ansible_host=${data.ip} vmid=${data.vmid}
%{ endif ~}
%{ endfor ~}

[k3s_cluster:children]
k3s_master
k3s_workers

