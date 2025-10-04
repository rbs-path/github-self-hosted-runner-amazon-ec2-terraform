ENVS := dev prod
env :=  dev
KEY := $(shell pwd | xargs basename)
TF_ENV_VARS := 
AWS_ENV :=
S3_PATH :=
WS :=

.PHONY: help
help:
	@echo "make (plan|apply|destroy|import|autoapply) [env=]"
	@echo "		e.g. make plan env=(`echo $(ENVS) | tr ' ' \|`) [default: $(env)]"
	@echo " "
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

tf_ws:
    ifeq ($(filter $(env),$(ENVS)),)
	 $(error $(env) is not supported)
    endif
	$(eval WS := $(shell $(TF_ENV_VARS) terraform workspace list))
	@if [ -z "$(filter $(env), $(WS))" ]; then $(TF_ENV_VARS) terraform workspace new $(env) ; else $(TF_ENV_VARS) terraform workspace select $(env); fi

tf_vars:
	$(eval TF_OPTIONS :=  $(TF_OPTIONS) -var-file "environments/$(env).tfvars")

.PHONY: init
init: 
    ifeq ($(filter $(env),$(ENVS)),)
	 $(error $(env) is not supported)
    endif
	$(eval TF_ENV_VARS := $(TF_ENV_VARS) )
	@echo "# TF_ENV_VARS: $(TF_ENV_VARS)"
	$(TF_ENV_VARS) terraform init

.PHONY: plan 
plan: tf_ws tf_vars
    ifneq ($(target),)
	  $(eval TF_OPTIONS :=  $(TF_OPTIONS) "-target=$(target)")
    endif 
    ifneq ($(out),)
	  $(eval TF_OPTIONS :=  $(TF_OPTIONS) -out="$(out)")
    endif 
	$(TF_ENV_VARS) terraform plan $(TF_OPTIONS)

.PHONY: apply
apply: tf_ws tf_vars
    ifneq ($(target),)
	  $(eval TF_OPTIONS :=  $(TF_OPTIONS) "-target=$(target)")
    endif 
    ifneq ($(out),)
	  $(eval TF_OPTIONS :=  $(TF_OPTIONS) "$(out)")
    endif 
	$(TF_ENV_VARS) terraform apply $(TF_OPTIONS)

.PHONY: destroy 
destroy: tf_ws tf_vars
	$(TF_ENV_VARS) terraform destroy $(TF_OPTIONS)

.PHONY: import 
import: tf_ws tf_vars
	$(TF_ENV_VARS) terraform import $(TF_OPTIONS) $(dst) $(src)

.PHONY: autoapply
autoapply: tf_ws tf_vars
	$(TF_ENV_VARS) terraform apply -auto-approve $(TF_OPTIONS)
