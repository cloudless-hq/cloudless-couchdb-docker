ks_namespace := kube-system
ks_secret := sealed-secrets-key
ks_master := master.key

RED=$(shell tput setaf 1)
GREEN=$(shell tput setaf 2)
YELLOW=$(shell tput setaf 3)
BOLD=$(shell tput bold)
RST=$(shell tput sgr0)

kubeseal-backup:
	kubectl get secret -n $(ks_namespace) $(ks_secret) -o yaml >$(ks_master)

kubeseal-deploy:
	kubectl replace secret -n $(ks_namespace) $(ks_secret) -f $(ks_master)
	kubectl delete pod -n $(ks_namespace) -l name=sealed-secrets-controller
	@echo "Try: $(RED)$(BOLD)kubectl get pods -n $(ks_namespace) -l name=sealed-secrets-controller -w$(RST) to confirm it started!"
