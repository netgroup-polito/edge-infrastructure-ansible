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

# Monitoring
Il role ```monitoring``` si occupa di installare e configurare la parte di monitoraggio.
Questo ruolo parte subito dopo la creazione del cluster k3s.
In ordine si occuperà di:

1. Controllare su curl è installato (ed installarlo eventualmente)
1. Installare helm (se non presente)
1. Installare Prometheus e Grafana (se non presente)
1. Installare Kepler (con annessa dashboard per Grafana) (se non presente)

In assenza di ingress per grafana, è possibile esporre ed accedere a grafana tramite nodeport con il seguente comando:

```sudo kubectl expose service prometheus-grafana --type=NodePort --name=grafana-ext --target-port=3000 -n monitoring```

### Grafana configuration

La configurazione di grafana è situata in ```playbook/roles/monitoring/files/values.yaml``` dove la password dello user ```admin``` è settata tramite l'attributo ```adminPassword```.

Se la configurazione non viene modificata, è possibile accedere a grafana con le seguenti credenziali:

- user: ```admin```
- password: ```prom-operator```
