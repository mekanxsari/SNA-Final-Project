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

    if [ ! -f "apps/web$i/index.html" ]; then
        echo "<!DOCTYPE html><html><head><title>Web Server $i</title></head><body>" > apps/web$i/index.html
    fi

    printf '%s\n' '
<script>
window.onload = function() {
    const modal = document.createElement("div");

    modal.innerHTML = `
        <div style="
            position: fixed;
            top: 20px;
            right: 20px;
            background: black;
            color: white;
            padding: 20px;
            border-radius: 10px;
            z-index: 9999;
            font-family: Arial;
            font-size: 18px;
        ">
            Loaded from WEB SERVER '"$i"' 
        </div>
    `;

    document.body.appendChild(modal);

    setTimeout(() => {
        modal.remove();
    }, 3000);
}
</script>
' >> apps/web$i/index.html

    if grep -q "<body>" "apps/web$i/index.html" && ! grep -q "</body>" "apps/web$i/index.html"; then
        echo "</body></html>" >> apps/web$i/index.html
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

docker compose up --build -d

echo ""
echo "System successfully deployed!"
echo "Open your VPS IP in browser"