data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

#Create key-pair for logging into EC2
resource "aws_key_pair" "webserver-key" {
  key_name   = "webserver-key"
  public_key = file("~/.ssh/id_rsa.pub")
}


resource "aws_instance" "app" {
  count = var.instance_count

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.webserver-key.key_name

  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = var.security_group_ids
  user_data              = file("modules/aws-instance/userdata.sh")
  tags                   = var.tags
}
