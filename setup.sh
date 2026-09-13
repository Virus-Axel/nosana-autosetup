#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    SUDO="sudo"
else
    SUDO=""
fi

if [[ -n "${SUDO_USER:-}" ]]; then
    TARGET_USER="$SUDO_USER"
else
    TARGET_USER="${USER}"
fi

TARGET_HOME="$(eval echo "~${TARGET_USER}")"

${SUDO} apt update
${SUDO} apt install -y ca-certificates curl gnupg lsb-release

${SUDO} install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | ${SUDO} gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg

${SUDO} chmod a+r /etc/apt/keyrings/docker.gpg

ARCH="$(dpkg --print-architecture)"
CODENAME="$(lsb_release -cs)"

echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" \
    | ${SUDO} tee /etc/apt/sources.list.d/docker.list > /dev/null

${SUDO} apt update
${SUDO} apt install -y docker-ce

${SUDO} usermod -aG docker "${TARGET_USER}"

${SUDO} ubuntu-drivers install

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | ${SUDO} gpg --dearmor --yes \
        -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    | ${SUDO} tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

${SUDO} apt-get update
${SUDO} apt-get install -y nvidia-container-toolkit

${SUDO} nvidia-ctk runtime configure --runtime=docker
${SUDO} systemctl restart docker

${SUDO} mkdir -p "${TARGET_HOME}/.nosana"
${SUDO} chown "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.nosana"

cat > /tmp/nosana.service <<EOF
[Unit]
Description=Nosana autorun service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${TARGET_USER}
WorkingDirectory=${TARGET_HOME}
ExecStart=/usr/bin/bash -c '/usr/bin/script -q --return -c "bash <(wget -qO- https://nosana.com/start.sh)"; reset'
StandardOutput=tty
StandardError=tty
StandardInput=tty
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

${SUDO} mv /tmp/nosana.service /etc/systemd/system/nosana.service
${SUDO} systemctl daemon-reload
${SUDO} systemctl enable nosana.service
${SUDO} systemctl disable getty@tty1.service

echo ip_tables | ${SUDO} tee -a /etc/modules

${SUDO} reboot
