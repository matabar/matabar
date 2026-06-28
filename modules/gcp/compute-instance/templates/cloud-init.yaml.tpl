#cloud-config
package_update: true
package_upgrade: true

packages:
  - docker.io
  - docker-compose-plugin
  - nginx
  - certbot
  - python3-certbot-nginx
  - dnsutils
  - curl

write_files:
  - path: /opt/app/docker-compose.yml
    permissions: "0644"
    content: |
${indent(6, docker_compose_content)}
  - path: /etc/nginx/sites-available/${web_domain}
    permissions: "0644"
    content: |
${indent(6, nginx_site_content)}
  - path: /etc/ssh/sshd_config.d/99-hardening.conf
    permissions: "0644"
    content: |
      PasswordAuthentication no
      PermitRootLogin no
      KbdInteractiveAuthentication no
  - path: /usr/local/bin/bootstrap-web-stack.sh
    permissions: "0755"
    content: |
      #!/bin/bash
      set -euo pipefail

      if [ -f /var/lib/bootstrap-complete ]; then
        exit 0
      fi

      EXTERNAL_IP=$(curl -fsS -H "Metadata-Flavor: Google" \
        http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)

      for _ in $(seq 1 60); do
        RESOLVED=$(dig +short "${web_domain}" @8.8.8.8 | tail -n1)
        if [ "$RESOLVED" = "$EXTERNAL_IP" ]; then
          break
        fi
        sleep 10
      done

      certbot --nginx \
        -d "${web_domain}" \
        --non-interactive \
        --agree-tos \
        -m "${certbot_email}" \
        --redirect

      touch /var/lib/bootstrap-complete

runcmd:
  - systemctl enable --now docker
  - docker compose -f /opt/app/docker-compose.yml up -d
  - rm -f /etc/nginx/sites-enabled/default
  - ln -sf /etc/nginx/sites-available/${web_domain} /etc/nginx/sites-enabled/${web_domain}
  - nginx -t
  - systemctl reload nginx
  - /usr/local/bin/bootstrap-web-stack.sh
  - systemctl reload ssh
