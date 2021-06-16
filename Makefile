AWS_PROFILE				:= qed-master
AWS_REGION				:= eu-west-2
DIR_TERRAFORM			:= example
FILE_CREDENTIALS_DOCKER	:= /tmp/credentials
FILE_CREDENTIALS_HOST	:= $(HOME)/.aws/credentials
TF_VERSION				:= 0.14.3
TF_IMAGE				:= hashicorp/terraform:$(TF_VERSION)
TF_DOCS_VERSION			:= 0.14.1
TF_DOCS_IMAGE			:= quay.io/terraform-docs/terraform-docs:$(TF_DOCS_VERSION)
TF_CHECKOV_VERSION		:= 1.0.625
TF_CHECKOV_IMAGE		:= bridgecrew/checkov:$(TF_CHECKOV_VERSION)
TF_BIND_DIR				:= /terraform
SHELLCHECK_URL			:= https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-stable.linux.x86_64.tar.xz

ifneq (,$(wildcard $(FILE_CREDENTIALS_HOST)))
	MOUNT_CREDENTIALS_FILE := -v $(FILE_CREDENTIALS_HOST):$(FILE_CREDENTIALS_DOCKER)
endif
ifeq (1,$(DISABLE_COLOR))
	NO_COLOR	:= -no-color
endif

TF_CMD = docker run \
			--rm \
			--user $(shell id -u) \
			--mount type=bind,source="$(shell pwd)",destination=$(TF_BIND_DIR) \
			-w $(TF_BIND_DIR) \
			--env AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
			--env AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
			--env TF_DATA_DIR=$(TF_BIND_DIR)/.terraform \
			--env AWS_PROFILE=$(AWS_PROFILE) \
			--env AWS_SHARED_CREDENTIALS_FILE=$(FILE_CREDENTIALS_DOCKER) \
			--env AWS_SDK_LOAD_CONFIG=1 \
			--env AWS_DEFAULT_REGION=$(AWS_REGION) \
			$(MOUNT_CREDENTIALS_FILE) \
			$(TF_IMAGE)

TF_CHECKOV_CMD = docker run \
					--rm \
					--mount type=bind,source="$(shell pwd)",destination=$(TF_BIND_DIR) \
					-w $(TF_BIND_DIR) \
					$(TF_CHECKOV_IMAGE) \
					-d $(TF_BIND_DIR)

docs:
	docker run \
		--rm \
		--user $(shell id -u) \
		--mount type=bind,source="$(shell pwd)",destination=$(TF_BIND_DIR) \
		-w $(TF_BIND_DIR) \
		$(TF_DOCS_IMAGE) \
		markdown .

install_shellcheck:
	@echo "Installing shellcheck..."
	@curl -sL $(SHELLCHECK_URL) -o /tmp/shellcheck.tar.xz
	@tar -xJf /tmp/shellcheck.tar.xz --strip-components 1 -C /tmp
	@mv /tmp/shellcheck /usr/local/bin/shellcheck
	@rm -rf /tmp/shellcheck.tar.xz


init:
	$(TF_CMD) init \
		$(NO_COLOR) \
		$(DIR_TERRAFORM)

check-fmt:
	$(TF_CMD) fmt -check .
	$(TF_CMD) fmt -check test

fmt:
	$(TF_CMD) fmt

plan:
	$(TF_CMD) plan \
		$(NO_COLOR) \
		$(DIR_TERRAFORM)

scan:
	$(TF_CHECKOV_CMD)

shell:
	$(eval OVERRIDE_ENTRYPOINT = -it --entrypoint sh)
	$(TF_CMD)

clean:
	rm -rf .terraform

shellcheck: SCRIPTS=$(shell find . -type f -name "*.sh" -exec echo {} \;)
shellcheck:
	@errors=0; \
	for i in $(SCRIPTS); do \
		if ! shellcheck "$$i"; then \
			printf "$$i \e[91m✘\e[0m\n"; \
			errors=`expr $$errors + 1`; \
		else \
			printf "$$i \e[92m✔\e[0m\n"; \
		fi; \
	done; \
	if [ $$errors != 0 ]; then \
	   exit 1; \
	fi


.PHONY: init check-fmt plan shell clean install_shellcheck shellcheck
