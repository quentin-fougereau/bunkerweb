# Variables
variable "linux_ip" {
  type     = string
  nullable = false
}
variable "linux_ip_id" {
  type     = string
  nullable = false
}

# Create cicd_bw_linux SSH key
resource "scaleway_account_ssh_key" "ssh_key" {
    name       = "cicd_bw_linux"
    public_key = file("~/.ssh/id_rsa.pub")
}

# Create cicd_bw_linux instance
resource "scaleway_instance_server" "instance" {
  depends_on = [scaleway_account_ssh_key.ssh_key]
  name = "cicd_bw_linux"
  type = "DEV1-M"
  image = "debian_bullseye"
  ip_id = var.linux_ip_id
}

# Create Ansible inventory file
resource "local_file" "ansible_inventory" {
  content = templatefile("templates/linux_inventory.tftpl", {
    public_ip = var.linux_ip
  })
  filename = "/tmp/linux_inventory"
}
