#!/bin/bash

echo "INFO: Installing oidc script"

# oidc (irsa)

echo "INFO: generating oidc script and systemd service+timer"
tee /usr/local/bin/oidc >/dev/null << EOM
#!/bin/bash

echo "decoding x509"
awk -F': ' '/client-certificate-data/ {print \$2}' /etc/rancher/rke2/rke2.yaml | base64 -d > /etc/rancher/rke2/system.admin.pem && chmod 400 /etc/rancher/rke2/system.admin.pem
awk -F': ' '/client-key-data/ {print \$2}' /etc/rancher/rke2/rke2.yaml | base64 -d > /etc/rancher/rke2/system.admin.key && chmod 400 /etc/rancher/rke2/system.admin.key
awk -F': ' '/certificate-authority-data/ {print \$2}' /etc/rancher/rke2/rke2.yaml | base64 -d > /etc/rancher/rke2/system.ca.pem && chmod 400 /etc/rancher/rke2/system.ca.pem

echo "decoding thumbprint"
openssl x509 -in /etc/rancher/rke2/system.ca.pem -fingerprint -noout | awk -F'=' 'gsub(/:/,"",\$0) { print \$2 }' > /etc/rancher/rke2/system.ca.thumbprint && chmod 400 /etc/rancher/rke2/system.ca.thumbprint

echo "fetching oidc"
curl --cert /etc/rancher/rke2/system.admin.pem --key /etc/rancher/rke2/system.admin.key --cacert /etc/rancher/rke2/system.ca.pem https://localhost:6443/.well-known/openid-configuration > /etc/rancher/rke2/oidc
curl --cert /etc/rancher/rke2/system.admin.pem --key /etc/rancher/rke2/system.admin.key --cacert /etc/rancher/rke2/system.ca.pem https://localhost:6443/openid/v1/jwks > /etc/rancher/rke2/jwks

echo "posting oidc to s3 (private)"
aws --region $REGION s3 cp /etc/rancher/rke2/system.ca.thumbprint s3://$PREFIX-$SUFFIX-private/oidc/thumbprint
aws --region $REGION s3 cp /etc/rancher/rke2/oidc s3://$PREFIX-$SUFFIX-private/oidc/.well-known/openid-configuration
aws --region $REGION s3 cp /etc/rancher/rke2/jwks s3://$PREFIX-$SUFFIX-private/oidc/openid/v1/jwks
EOM

chmod 700 /usr/local/bin/oidc

tee /etc/systemd/system/rke2-oidc.service >/dev/null << EOM
[Unit]
Description=Generates oidc files from rke2 api server and publishes to s3 every 23h
After=network.target
[Service]
ExecStart=/usr/local/bin/oidc
Type=simple
Restart=no
[Install]
WantedBy=multi-user.target
EOM

tee /etc/systemd/system/rke2-oidc.timer >/dev/null << EOM
[Unit]
Description=Generates oidc files from rke2 api server and publishes to s3 every 23h
[Timer]
OnUnitActiveSec=23h
Unit=rke2-oidc.service
[Install]
WantedBy=multi-user.target
EOM

echo "INFO: activating oidc script and systemd service+timer"
systemctl daemon-reload
systemctl enable rke2-oidc.service rke2-oidc.timer
systemctl start rke2-oidc.service rke2-oidc.timer
