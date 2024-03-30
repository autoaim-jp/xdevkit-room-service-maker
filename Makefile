include setting/version.conf
SHELL=/bin/bash
PHONY=default create-app create-pull-request help 

.PHONY: $(PHONY)

default: create-app

create-app: create_app_validation git_clone_template clean_git setup_xdevkit replace_project_name replace_xdevkit_version generate_dot_env update_port make_dummy_cert fetch_letsencrypt register_with_nginx save_port git_commit_push show_develop_hint start

create-pull-request: create_pull_request_validation create_pull_request

help:
	@echo "Usage: "
	@echo "	make create-app project=<project dir name> origin=<fqdn like client.example.com> port=<server port>"
	@echo "	make create-pull-request project=<project dir name> version=<branch to merge>"
	@echo "	make help"

PROJECT_DIR_PATH := ./project/$(project)
ERROR_MSG := Invalid argument. 'make help' will help you
BRANCH := `git branch --contains | cut -d " " -f 2 | tr -d '\n'`

create_app_validation:
ifndef project
	$(error $(ERROR_MSG))
endif
ifndef origin
	$(error $(ERROR_MSG))
endif
ifndef port
	$(error $(ERROR_MSG))
endif

create_pull_request_validation:
ifndef project
	$(shell help)
endif
ifndef version 
	$(error $(ERROR_MSG))
endif

create_pull_request:
	@cd $(PROJECT_DIR_PATH) && gh pr create --base master --head $(version) --title "merge: $(version) from xdevkit-room-service-maker" --body ""

git_clone_template:
	@git clone https://github.com/autoaim-jp/xlogin-jp-client-sample $(PROJECT_DIR_PATH)

clean_git:
	@rm -rf $(PROJECT_DIR_PATH)/.git && rm $(PROJECT_DIR_PATH)/.gitmodules
	@cd $(PROJECT_DIR_PATH)/ && git init

setup_xdevkit:
	@rm -rf $(PROJECT_DIR_PATH)/xdevkit
	@cd $(PROJECT_DIR_PATH)/ && git submodule add -b ${XDEVKIT_VERSION} https://github.com/autoaim-jp/xdevkit
	@cd $(PROJECT_DIR_PATH)/ && make init

replace_project_name:
	@sed -i -e 's/DOCKER_PROJECT_NAME=xljp-sample/DOCKER_PROJECT_NAME=$(project)/' $(PROJECT_DIR_PATH)/setting.conf
	@sed -i -e 's/xlcs-/$(project)-/' $(PROJECT_DIR_PATH)/app/docker/docker-compose.app.yml

replace_xdevkit_version:
	@sed -i -e "s/XDEVKIT_VERSION=.*/XDEVKIT_VERSION=$(BRANCH)/" $(PROJECT_DIR_PATH)/setting.conf

generate_dot_env:
	@./core/generateDotEnv.sh $(origin) $(PROJECT_DIR_PATH)/service/staticWeb/src/.env staticWeb

update_port:
	@sed -i -e 's/3001/$(port)/g' $(PROJECT_DIR_PATH)/app/docker/docker-compose.app.yml
	@sed -i -e 's/3001/$(port)/g' $(PROJECT_DIR_PATH)/service/staticWeb/src/.env

make_dummy_cert:
	@cd $(PROJECT_DIR_PATH)/service/staticWeb/src/ && \
		mkdir ./cert/ && \
		cd ./cert/ && \
		openssl genrsa 4096 > server.key && \
		openssl req -new -batch -key server.key > server.csr && \
		openssl x509 -days 3650 -req -signkey server.key < server.csr > server.crt

fetch_letsencrypt:
	@sudo whoami
	@sudo certbot -d $(origin) certonly --nginx --keep

register_with_nginx:
	@sudo whoami
	@sudo cp setting/nginx-template.conf /etc/nginx/conf.d/`basename $(origin)`.conf
	@sudo sed -i -e 's/sample.xlogin.jp/$(origin)/g' /etc/nginx/conf.d/`basename $(origin)`.conf
	@sudo sed -i -e 's/localhost:3001/localhost:$(port)/g' /etc/nginx/conf.d/`basename $(origin)`.conf
	@sudo systemctl reload nginx

save_port:
	@echo $(port) > last-port.txt

git_commit_push:
	@cd $(PROJECT_DIR_PATH) && git config user.email ${GIT_EMAIL} && git config user.user ${GIT_USER}
	@cd $(PROJECT_DIR_PATH) && git add . && git commit -a -m 'generated from xdevkit-starter'
	@cd $(PROJECT_DIR_PATH) && gh repo create --push --${GIT_VISIBILITY} --source=.

show_develop_hint:
	@echo "=================================================="
	@echo "Before edit logo and title, switch branch!"
	@echo "=================================================="

start:
	@cd $(PROJECT_DIR_PATH)/ && make


