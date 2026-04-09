# Kubernetes 2-Node Assignment (1 Master + 1 Worker)

This guide is tailored to your two EC2 instances:
- Master: `54.255.182.118` (key: `D:\\Downloads\\k8s-master.pem`)
- Worker: `13.250.19.137` (key: `D:\\Downloads\\k8s-worker1.pem`)

Assumptions:
- Ubuntu 22.04 on both nodes
- You can SSH as `ubuntu`
- You are using AWS EC2 security groups

## 1) Open required EC2 ports

In security groups, allow these inbound rules:
- SSH: 22 (your IP only)
- Kubernetes API: 6443 (worker SG -> master SG)
- etcd: 2379-2380 (master only)
- kubelet: 10250 (master/worker SG internal)
- NodePort range: 30000-32767 (for app testing)
- Calico VXLAN: UDP 4789 (node-to-node)
- Calico BGP (optional): TCP 179 (node-to-node)

## 2) SSH into both nodes

From Windows PowerShell:

```powershell
ssh -i "D:\Downloads\k8s-master.pem" ubuntu@54.255.182.118
ssh -i "D:\Downloads\k8s-worker1.pem" ubuntu@13.250.19.137
```

## 3) Run base setup on BOTH nodes

Run this on master and worker:

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y containerd kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```

## 4) Initialize MASTER node

Run on master (`54.255.182.118`):

```bash
MASTER_PRIVATE_IP=$(hostname -I | awk '{print $1}')

sudo kubeadm init \
  --apiserver-advertise-address=$MASTER_PRIVATE_IP \
  --pod-network-cidr=192.168.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/calico.yaml
```

Get join command:

```bash
kubeadm token create --print-join-command
```

Copy output; it looks like:

```bash
sudo kubeadm join <MASTER_PRIVATE_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

## 5) Join WORKER node

Run the join command on worker (`13.250.19.137`) with `sudo`.

Verify from master:

```bash
kubectl get nodes -o wide
```

Expected: master `Ready`, worker `Ready`.

## 6) Deploy dummy 3-tier app

From master, copy this repo file to master first (or create it directly there):
- `k8s-assignment/manifests/3tier-dummy.yaml`

Apply it:

```bash
kubectl apply -f 3tier-dummy.yaml
kubectl get all -n assignment-app
```

Check NodePort service:

```bash
kubectl get svc -n assignment-app
```

Expected frontend NodePort: `30080`.

Access app in browser:

```text
http://13.250.19.137:30080
```

(Use worker public IP if pods run on worker.)

## 7) Quick verification commands (for screenshots)

```bash
kubectl get nodes -o wide
kubectl get pods -n assignment-app -o wide
kubectl get svc -n assignment-app
kubectl describe node
```

## 8) Troubleshooting

- If node is `NotReady`:
  - `sudo systemctl status containerd kubelet`
  - `kubectl get pods -n kube-system`
- If join fails with token expiry:
  - On master: `kubeadm token create --print-join-command`
- If frontend unreachable:
  - Open NodePort range in security group
  - `kubectl get pods -n assignment-app -o wide`
  - Try worker IP and master IP

## 9) Cleanup (optional)

```bash
kubectl delete ns assignment-app
```
