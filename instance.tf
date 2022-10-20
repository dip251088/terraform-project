resource "aws_instance" "Webapp1" {
  ami           = "ami-062df10d14676e201"
  key_name = "first-linux-instance-25"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.demo-subnet-1a.id
  vpc_security_group_ids = [ aws_security_group.allow_80_22.id ]
  tags = {
    Name = "Webapp-1"
  }
}

resource "aws_instance" "Webapp2" {
  ami           = "ami-062df10d14676e201"
  key_name = "first-linux-instance-25"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.demo-subnet-1b.id
  vpc_security_group_ids = [ aws_security_group.allow_80_22.id ]
  tags = {
    Name = "Webapp-2"
  }
}