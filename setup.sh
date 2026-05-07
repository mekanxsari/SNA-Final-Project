#!/bin/bash

set -e

rm -rf apps temp_repo nginx docker-compose.yml
mkdir -p apps nginx

clear

echo "========================================="
echo " Static Web Cluster Generator"
echo "========================================="

echo ""
read -p "Enter GitHub repository URL: " REPO_URL
read -p "How many web servers? " SERVER_COUNT

echo ""
echo "Choose load balancing algorithm"
echo ""
echo "1) round_robin"
echo "2) least_conn"
echo "3) ip_hash"
echo ""
read -p "Choice: " LB_CHOICE

if [ "$LB_CHOICE" = "1" ]; then
    SCHEDULER=""
elif [ "$LB_CHOICE" = "2" ]; then
    SCHEDULER="least_conn;"
elif [ "$LB_CHOICE" = "3" ]; then
    SCHEDULER="ip_hash;"
else
    echo "Invalid choice"
    exit 1
fi

echo ""
echo "Cloning repository..."

git clone "$REPO_URL" temp_repo

echo ""
echo "Creating containers..."

for i in $(seq 1 $SERVER_COUNT)
do
    mkdir -p apps/web$i

    cp -r temp_repo/* apps/web$i/
    cp -r temp_repo/.[!.]* apps/web$i/ 2>/dev/null || true

    if [ -f "apps/web$i/index.html" ]; then
        if ! grep -q "Loaded from WEB SERVER" "apps/web$i/index.html" 2>/dev/null; then
            cat > /tmp/popup_$$.txt <<EOF
<script>
(function() {
    const modal = document.createElement("div");
    modal.innerHTML = '<div style="position:fixed;top:20px;right:20px;background:#D4C5F9;color:#6347a6;padding:20px;border-radius:10px;z-index:9999;font-family:Arial;font-size:18px;font-weight:bold;box-shadow:0 4px 6px rgba(0,0,0,0.1);">Loaded from WEB SERVER $i</div>';
    document.body.appendChild(modal);
    setTimeout(() => modal.remove(), 3000);
})();
</script>
EOF
            if grep -q "</body>" "apps/web$i/index.html"; then
                sed -i "/<\/body>/r /tmp/popup_$$.txt" "apps/web$i/index.html"
                sed -i "/<\/body>/i\\" "apps/web$i/index.html" 2>/dev/null || true
            else
                cat /tmp/popup_$$.txt >> "apps/web$i/index.html"
            fi
            
            rm -f /tmp/popup_$$.txt
        fi
    fi

    cat <<EOF > apps/web$i/Dockerfile
FROM nginx:alpine

COPY . /usr/share/nginx/html
EOF

done

echo "Generating nginx.conf..."

cat <<EOF > nginx/nginx.conf
events {}

http {

    upstream backend {
        $SCHEDULER
EOF

for i in $(seq 1 $SERVER_COUNT)
do
    echo "        server web$i:80;" >> nginx/nginx.conf
done

cat <<EOF >> nginx/nginx.conf
    }

    server {
        listen 80;

        location / {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Cache-Control "no-cache, no-store, must-revalidate";
            proxy_set_header Pragma "no-cache";
            proxy_set_header Expires "0";
        }
    }
}
EOF

echo "Generating docker-compose.yml..."

cat <<EOF > docker-compose.yml
services:
  nginx:
    image: nginx:latest
    container_name: nginx_lb
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
EOF

for i in $(seq 1 $SERVER_COUNT)
do
    echo "      - web$i" >> docker-compose.yml
done

for i in $(seq 1 $SERVER_COUNT)
do
cat <<EOF >> docker-compose.yml

  web$i:
    build: ./apps/web$i
    container_name: web$i
EOF

done

echo ""
echo "Starting system..."

if docker compose version &> /dev/null; then
    docker compose up -d --build
elif docker-compose version &> /dev/null; then
    docker-compose up --build -d
else
    echo "Error: Neither 'docker compose' nor 'docker-compose' found"
    exit 1
fi

echo ""
echo "System successfully deployed!"
echo "Open your VPS IP in browser"