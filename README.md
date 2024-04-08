# ansible_project_k3s
Per eseguirlo:
```bash
ansible-playbook --ask-become-pass playbook/k3s_installation.yaml -i inventory
```
```bash
ansible-playbook --ask-become-pass playbook/dashboard_deploy.yaml -i inventory
```
Per recuperare il token per la dashboard dal mini-pc: 
```bash
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d
```
