resource "aws_key_pair" "my_keypair" {
  key_name   = var.keypair_name
  public_key = file(var.pub_key_path)
}