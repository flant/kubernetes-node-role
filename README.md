# kubernetes-node-role
Настраивает toleration и nodeAffinity для kube-dns, kube-proxy и kube-flannel-ds

Для настройки ежедневного автообновления:
```
cat > /etc/cron.d/kubernetes-node-role <<END
48 3 * * * root curl -s https://raw.githubusercontent.com/flant/kubernetes-node-role/master/ctl.sh | bash -s - 
END
```
