# Load Balancer

## Stack

- HTML/CSS/JS
- Docker
- Docker Compose
- NGINX
- Bash Script Automation

---

## Features

- GitHub static site deployment
- Dynamic cluster generation
- NGINX load balancing
- Round Robin / Least Connections / IP Hash
- Automatic Dockerfile generation
- Automatic docker-compose generation
- Modal shows which server handled request

---

## Install Dependencies

Ubuntu/Debian:

```bash
sudo apt update
sudo apt install docker.io docker-compose git -y
```

Enable Docker:

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

> **Important:** If NGINX is already installed on your system, stop it to avoid port conflict:
> ```bash
> sudo systemctl stop nginx
> sudo systemctl disable nginx
> ```

---

## Make Script Executable

```bash
chmod +x setup.sh
```

---

## Run

```bash
./setup.sh
```

---

## Example

```text
Enter GitHub repository URL:
https://github.com/user/static-site

How many web servers?
3

Choose load balancing algorithm
1) round_robin
2) least_conn
3) ip_hash
```

### Load Balancing Algorithms

| Algorithm | Description |
|---|---|
| `round_robin` | Cycles requests evenly across all servers in sequence |
| `least_conn` | Routes to the server with the fewest active connections |
| `ip_hash` | Pins a client IP to a consistent backend server |

---

## Open Website

```text
http://YOUR_VPS_IP
```

Refresh multiple times to see different containers handling requests.


---

## Clean Up

Runs a full teardown: stops all containers, removes generated files, and wipes local images.

```bash
chmod +x clean.sh
./clean.sh
```