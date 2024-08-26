#vm_names    = ["Kubernetes-master", "Kubernetes-Worker1", "Kubernetes-Worker2"]
#vm_hostnames = {
#  kube-master = "kubemaster1"
#  kube-worker1 = "worker1-1"
#  kube-worker2 = "worker2-1"
#}
network     = "VM Network"
template    = "Ubunutu-Golden-image"
vm_username = "admin@vsphere.local"
vm_password = "Welcome@123"
vsphere_server = "172.16.165.10"
vsphere_datacenter = "Pi-Data"
vsphere_compute_cluster = "Pi-Data"
vm_ipv4_gateway  = "172.16.165.1"
