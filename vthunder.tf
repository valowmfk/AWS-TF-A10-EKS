# # Create A10 ADC

 resource "aws_instance" "vthunder" {
  ami               = "<ami_is_region_specific>" # Obtain AMI ID from AWS EC2 Console for your region
  instance_type     = "m4.xlarge"
  key_name          = "<your_key>"
  availability_zone = data.aws_availability_zones.available.names[0]
   network_interface {
    network_interface_id = aws_network_interface.vth-mngt-nic1.id
    device_index         = "0"
  }
   network_interface {
    network_interface_id = aws_network_interface.vth-public-nic1.id
    device_index         = "1"
    }   
   network_interface {
    network_interface_id = aws_network_interface.vth-private-nic1.id
    device_index         = "2"
  }
  tags = {
    Name = "${var.project}-ADC-1"
    }
 }
