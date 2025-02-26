# Variables
variable "k8s_ip" {
  type     = string
  nullable = false
}
variable "k8s_dockerconfigjson" {
  type = string
  nullable = false
}

# Create k8s cluster
resource "scaleway_k8s_cluster" "cluster" {
  type = "kapsule"
  name = "bw_k8s"
  version = "1.24.7"
  cni = "cilium"
}

# Create k8s pool
resource "scaleway_k8s_pool" "pool" {
  cluster_id = scaleway_k8s_cluster.cluster.id
  name = "bw_k8s"
  node_type = "DEV1-M"
  size = 3
  wait_for_pool_ready = true
}

# Get kubeconfig file
resource "local_file" "kubeconfig" {
  depends_on = [scaleway_k8s_pool.pool]
  content = scaleway_k8s_cluster.cluster.kubeconfig[0].config_file
  filename = "/tmp/k8s/kubeconfig"
}
provider "kubectl" {
  config_path = "${local_file.kubeconfig.filename}"
}

# Setup LB
resource "local_file" "lb_yml" {
  depends_on = [local_file.kubeconfig]
  content = templatefile("templates/lb.yml.tftpl", {
    lb_ip = var.k8s_ip
  })
  filename = "/tmp/k8s/lb.yml"
}
resource "kubectl_manifest" "lb" {
  depends_on = [local_file.lb_yml]
  yaml_body = local_file.lb_yml.content
}

# Setup registry
resource "local_file" "reg_yml" {
  depends_on = [local_file.kubeconfig]
  content = templatefile("templates/reg.yml.tftpl", {
    dockerconfigjson = var.k8s_dockerconfigjson
  })
  filename = "/tmp/k8s/reg.yml"
}
resource "kubectl_manifest" "reg" {
  depends_on = [local_file.reg_yml]
  yaml_body = local_file.reg_yml.content
}