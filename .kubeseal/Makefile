ks_namespace := kube-system
ks_secret := sealed-secrets-key
ks_master := master.key

kubeseal-backup:
	kubectl get secret -n $(ks_namespace) $(ks_secret) -o yaml >$(ks_master)

kubeseal-deploy:
	kubectl replace secret -n $(ks_namespace) $(ks_secret) $(ks_master)
	kubectl delete pod -n $(ks_namespace) -l name=sealed-secrets-controller
	@echo "Hit `kubectl -n $(ks_namespace) name=sealed-secrets-controller -w` to confirm it started!"
