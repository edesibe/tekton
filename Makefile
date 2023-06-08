SHELL = /bin/bash
UID = $(shell id -u) 
GID = $(shell id -g) 

ifndef VERBOSE
.SILENT:
endif

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: cluster-create
cluster-create: ; $(info Creating k3s cluster...) ## Create 3s cluster
	@curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -
	@make $(HOME)/.kube/config

$(HOME)/.kube/config: ## Setup kubeconfig
	@mkdir -p $(HOME)/.kube
	@sudo cp -v /etc/rancher/k3s/k3s.yaml $(HOME)/.kube/config
	@sudo chown $(USER):$(USER) $(HOME)/.kube/config

.PHONY: sops-setup
sops-setup: ; $(info Sops setup) ## Bootstraping sops and age
	@mkdir -p $(HOME)/.sops
	@age-keygen -o $(HOME)/.sops/key.txt

.PHONY: sops-encrypt
sops-encrypt: ; $(info Encrypting file with sops...Use 'make sops-encrypt FILENAME=<filename>') ## Encrypting file with sops
	@sops -i -e --encrypted-regex '^(data|stringData)$$' --age $(SOPS_AGE_RECIPIENTS) $(FILENAME)

.PHONY: sops-decrypt
sops-decrypt: ; $(info Decrypting file with sops...Use 'make sops-decrypt FILENAME=<filename>') ## Decrypting file with sops
	@sops -i -d $(FILENAME)


.PHONY: tekton-pipelines
tekton-pipelines: ; $(info Installing tekton pipelines...) ## Install tekton pipelines
	@kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

.PHONY: tekton-triggers
tekton-triggers: ; $(info Installing tektong triggers...) ## Install tekton triggers
	@kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
	@sleep 15
	@kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml

.PHONY: tekton-dashboard
tekton-dashboard: ; $(info Installing tekton dashboard...) ## Install tekton dashboard(read-only)
	@kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml

.PHONY: check-md
check-md: ; $(info Checking markdown...) ## Check Markdown output
	@pandoc README.md | lynx --stdin

.PHONY: cluster-destroy
cluster-destroy: ; $(info Delete k3s cluster...) ## Delete k3s cluster
	@sudo k3s-uninstall.sh
