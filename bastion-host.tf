resource "aws_instance" "bastion" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.my_keypair.key_name
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name    = "bastion"
    Project = var.proj_name
  }

  provisioner "file" {
    content     = templatefile("templates/db-initialize.tmpl", { rds_endpoint = aws_db_instance.my_rds.address, dbuser = var.dbuser, dbpass = var.dbpass, dbname = var.dbname })
    destination = "/tmp/db-initialize.sh"
  }

  connection {
    type        = "ssh"
    user        = var.ec2_username
    private_key = file(var.priv_key_path)
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/db-initialize.sh",
      "sudo /tmp/db-initialize.sh"
    ]
  }
}