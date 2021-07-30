SHELL = /bin/bash
UID = $(shell id -u)

SWAGGER_AGGREGATOR_IMAGE    ?= docker.onedata.org/swagger-aggregator:1.5.0
SWAGGER_CLI_IMAGE           ?= docker.onedata.org/swagger-cli:1.5.0
SWAGGER_BOOTPRINT_IMAGE     ?= docker.onedata.org/swagger-bootprint:1.5.0
SWAGGER_MARKDOWN_IMAGE      ?= docker.onedata.org/swagger-gitbook:1.4.1
SWAGGER_COWBOY_SERVER_IMAGE ?= docker.onedata.org/swagger-codegen:2.3.1-cowboy
SWAGGER_PYTHON_CLIENT_IMAGE ?= docker.onedata.org/swagger-codegen:2.3.1-cowboy
SWAGGER_BASH_CLIENT_IMAGE   ?= docker.onedata.org/swagger-codegen:VFS-6328

.PHONY : all swagger.json
all : cowboy-server python-client bash-client doc-static doc-markdown

clean:
	@rm -rf generated packages swagger.json

swagger.json:
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger:delegated ${SWAGGER_AGGREGATOR_IMAGE}

validate: swagger.json
	@RESULT="$(shell docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger:delegated ${SWAGGER_CLI_IMAGE} validate /swagger/swagger.json 2>&1)"; \
	if [[ $$RESULT =~ .*SyntaxError.* ]]; then\
		echo "$$RESULT";\
		exit 1;\
	else\
		echo "swagger.json is valid.";\
	fi

cowboy-server: validate
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger:delegated -t ${SWAGGER_COWBOY_SERVER_IMAGE} generate -Dapis -DapiFileNameSuffix="_routes" -i ./swagger.json -l cowboy -o ./generated/cowboy
	./fix_generated.py

python-client: validate
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger:delegated -t ${SWAGGER_PYTHON_CLIENT_IMAGE} generate -i ./swagger.json -l python -o ./generated/python -c python-config.json

bash-client: validate
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger:delegated -t ${SWAGGER_BASH_CLIENT_IMAGE} generate -i ./swagger.json -l bash -o ./generated/bash -c bash-config.json

doc-static: validate
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger:delegated -t ${SWAGGER_BOOTPRINT_IMAGE} swagger ./swagger.json generated/static

	@sed -n '/<body>/,/<\/body>/p' generated/static/index.html | sed -e '1s/.*<body>//' -e '$s/<\/body>.*//' -e 's/\/definitions\//definitions--/g' -e 's/<div class=\"container\"/<div class=\"container swagger\"/' > generated/static/oneprovider-static.html

doc-markdown: validate
	docker run --rm -v `pwd`:/swagger:delegated -t ${SWAGGER_MARKDOWN_IMAGE} convert -i ./swagger.json -d ./generated/gitbook -c ./gitbook.properties

preview: validate
	./bamboos/scripts/build-redoc.sh preview

bash-packages: RELEASES = $(shell git branch -a | grep "release/" | sed -n 's/.*release\/\(.*\)/\1/p')
bash-packages:
	@git checkout master
	@releases=(${RELEASES});\
	for release_branch in $${releases[@]}; do\
		echo "#################################################";\
		echo " Building Bash client release: $$release_branch";\
		echo "#################################################";\
		git checkout release/$$release_branch;\
		rm -rf generated;\
		docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger:delegated -t ${SWAGGER_AGGREGATOR_IMAGE};\
		docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger:delegated -t ${SWAGGER_BASH_CLIENT_IMAGE} generate -i ./swagger.json -l bash -o ./generated/bash -c bash-config.json;\
		mkdir -p "packages/bash/$$release_branch";\
		cp generated/bash/onezone-rest-cli "packages/bash/$$release_branch/";\
		cp generated/bash/_onezone-rest-cli "packages/bash/$$release_branch/";\
		cp generated/bash/onezone-rest-cli.bash-completion "packages/bash/$$release_branch/";\
	done;\
	custom_releases=( develop );\
	for release_branch in $${custom_releases[@]}; do\
		echo "#################################################";\
		echo " Building Bash client release: $$release_branch";\
		echo "#################################################";\
		git checkout $$release_branch;\
		rm -rf generated;\
		docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger:delegated -t ${SWAGGER_AGGREGATOR_IMAGE};\
		docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger:delegated -t ${SWAGGER_BASH_CLIENT_IMAGE} generate -i ./swagger.json -l bash -o ./generated/bash -c bash-config.json;\
		mkdir -p "packages/bash/$$release_branch";\
		cp generated/bash/onezone-rest-cli "packages/bash/$$release_branch/";\
		cp generated/bash/_onezone-rest-cli "packages/bash/$$release_branch/";\
		cp generated/bash/onezone-rest-cli.bash-completion "packages/bash/$$release_branch/";\
	done
	@git checkout master

submodules:
	git submodule sync --recursive ${submodule}
	git submodule update --init --recursive ${submodule}

codetag-tracker:
	./bamboos/scripts/codetag-tracker.sh --branch=${BRANCH} --excluded-dirs=