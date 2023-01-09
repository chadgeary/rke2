## Usage

Files put to S3 by terraform and run by EC2 instances at boot through an AWS SSM Assocation, starting with `bootstrap.sh`

## Flow

* ssm executes bootstrap.sh on each ec2 first power-on
* bootstrap.sh runs fips.sh (once)
* fips.sh creates post-fips-boostrap.sh systemd service, reboots

* systemd runs post-fips-bootstrap.sh
* post-fips-bootstrap.sh runs control-plane.sh or worker.sh
* control-plane.sh or worker.sh run:
  * label.sh (both)
  * oidc.sh (control-plane)
  * ecr.sh (both)
  * charts.sh (control-plane)
