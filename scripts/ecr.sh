#!/bin/bash

echo "INFO: Installing ecr auth script"

# ecr (registries)
if [ "$NODEGROUP" == "control-plane" ]; then
  RKE2_SYSTEMD_UNIT="rke2.service"
  export RKE2_SYSTEMD_UNIT
else
  RKE2_SYSTEMD_UNIT="rke2-agent.service"
  export RKE2_SYSTEMD_UNIT
fi

echo "INFO: generating registries script and systemd service+timer"
tee /usr/local/bin/registries >/dev/null << EOM
#!/bin/bash

echo "getting ecr password"
ECR_PASSWORD=\$(aws --region "$REGION" ecr get-login-password)

echo "rendering /etc/rancher/rke2/registries.yaml"
tee /etc/rancher/rke2/registries.yaml << EOT > /dev/null
mirrors:
  "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com":
    endpoint:
      - "https://$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"
  "$AWS_ADDON_URI":
    endpoint:
      - "https://$AWS_ADDON_URI"
configs:
  "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com":
    auth:
      username: AWS
      password: \$ECR_PASSWORD
  "$AWS_ADDON_URI":
    auth:
      username: AWS
      password: \$ECR_PASSWORD
EOT

echo "reloading rke2"
systemctl restart $RKE2_SYSTEMD_UNIT

EOM
chmod 700 /usr/local/bin/registries

tee /etc/systemd/system/rke2-registries.service >/dev/null << EOM
[Unit]
Description=Generates registries files from rke2 api server and publishes to s3 every 11h
After=network.target
[Service]
ExecStart=/usr/local/bin/registries
Type=simple
Restart=no
[Install]
WantedBy=multi-user.target
EOM

tee /etc/systemd/system/rke2-registries.timer >/dev/null << EOM
[Unit]
Description=Generates registries files from rke2 api server and publishes to s3 every 11h
[Timer]
OnUnitActiveSec=11h
Unit=rke2-registries.service
[Install]
WantedBy=multi-user.target
EOM

echo "INFO: activating registries script and systemd service+timer"
systemctl daemon-reload
systemctl enable rke2-registries.service rke2-registries.timer
systemctl start rke2-registries.service rke2-registries.timer
