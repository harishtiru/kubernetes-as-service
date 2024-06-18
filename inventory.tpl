[master]
%{ for vm_name in master_vms }
${vm_name} ansible_host=${vsphere_virtual_machine[vm_name].guest_ip_addresses[0]}
%{ endfor }

[workers]
%{ for vm_name in worker_vms }
${vm_name} ansible_host=${vsphere_virtual_machine[vm_name].guest_ip_addresses[0]}
%{ endfor }

