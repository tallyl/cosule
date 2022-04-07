

// Generate public key with TLS provider - Our private key will be stored in Terraform state.
resource "tls_private_key" "opsschool_Tally_consul_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "opsschool_Tally_consul_key" {
  key_name   = var.pem_key_name
  public_key = tls_private_key.opsschool_Tally_consul_key.public_key_openssh
}

resource "null_resource" "chmod_400_key" {
  provisioner "local-exec" {
    command = "chmod 400 ${path.module}/${local_file.private_key.filename}"
  }
}

// Generate our outputs :  our private key
resource "local_file" "private_key" {
  sensitive_content = tls_private_key.opsschool_Tally_consul_key.private_key_pem
  filename          = var.pem_key_name
  //file_permission   = "0400"
}