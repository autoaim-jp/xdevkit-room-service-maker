include setting/version.conf
SHELL=/bin/bash
PHONY=default app help 

.PHONY: $(PHONY)

default: app

app: validation git_clone_template clean_git setup_xdevkit replace_project_name generate_dot_env update_port make_dummy_cert fetch_letsencrypt register_with_nginx start

help:
	@echo "Usage: make app"
	@echo "Usage: make help"

PROJECT_DIR_PATH := ./project/$(project)
ERROR_MSG := Usage: make app project=<project dir name> origin=<fqdn like client.example.com> port=<server port>

validation:
ifndef project
	$(error $(ERROR_MSG))
endif
ifndef origin
	$(error $(ERROR_MSG))
endif
ifndef port
	$(error $(ERROR_MSG))
endif

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

generate_dot_env:
	@./core/generateDotEnv.sh $(origin) $(PROJECT_DIR_PATH)/service/staticWeb/src/.env

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

start:
	@cd $(PROJECT_DIR_PATH)/ && make


