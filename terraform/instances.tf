

resource "aws_instance" "consul_server" {
  count = var.consul_server_num
  ami           = lookup(var.ami, var.region)
  instance_type = "t2.micro"
  key_name      = aws_key_pair.opsschool_Tally_consul_key.key_name
  subnet_id                   = data.aws_subnets.public_subnets.ids[count.index]
  iam_instance_profile   = aws_iam_instance_profile.consul-join.name
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.consul_sg.id]
  # Copies the myapp.conf file to /etc/myapp.conf
  #provisioner "file" {
  #  source      = "conf/consul.service"
  #  destination = "/etc/systemd/system/consul.service"
  #}

  #provisioner "file" {
  #  source      = "conf/resolve.conf"
  #  destination = "/etc/systemd/resolved.conf.d/consul.conf"
  #}

  user_data            =   templatefile("/templates/user_data.sh", {config = file("conf/server_config.json"), agent=0})
  #user_data   = data.template_cloudinit_config.consul_server_cloud_init.rendered


  tags = merge(
    var.common_tags, {"Name" = "${var.deployment_name}-${var.purpose}-server-${count.index}"} , {"consul_server" = "true"} )

}

resource "aws_instance" "consul_agent" {
  count = var.consul_agent_num
  ami                         = lookup(var.ami, var.region)
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.opsschool_Tally_consul_key.key_name
  subnet_id                   = data.aws_subnets.public_subnets.ids[count.index]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.consul-join.name
  vpc_security_group_ids      = [aws_security_group.consul_sg.id]

  # Copies the myapp.conf file to /etc/myapp.conf
  #provisioner "file" {
  #  source      = "conf/consul.service"
  #  destination = "/etc/systemd/system/consul.service"
  #}

  #provisioner "file" {
  #  source      = "conf/resolve.conf"
  #  destination = "/etc/systemd/resolved.conf.d/consul.conf"
  #}
  user_data            =   templatefile("/templates/user_data.sh", {config = file("conf/agent_config.json"), agent=1})

  tags = merge(
  var.common_tags, { "Name" = "${var.deployment_name}-${var.purpose}-agent-${count.index}" }, {
    "consul_server" = "false"
  } )
}

 
