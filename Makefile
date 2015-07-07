all: build

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""
	@echo "   1. make build        - build the gitlab-ci image"
	@echo "   2. make quickstart   - start gitlab-ci"
	@echo "   3. make stop         - stop gitlab-ci"
	@echo "   4. make logs         - view logs"
	@echo "   5. make purge        - stop and remove the container"

build:
	@docker build --tag=${USER}/gitlab-ci .

release: build
	@docker build --tag=${USER}/gitlab-ci:$(shell cat VERSION) .

quickstart:
	@echo "Starting postgresql..."
	@docker run --name=gitlab-ci-postgresql -d \
		--env='DB_NAME=gitlab_ci_production' \
		--env='DB_USER=gitlab' --env='DB_PASS=password' \
		sameersbn/postgresql:latest >/dev/null
	@echo "Starting redis..."
	@docker run --name=gitlab-ci-redis -d \
		sameersbn/redis:latest >/dev/null
	@echo "Starting gitlab-ci..."
	@docker run --name=gitlab-ci-demo -d \
		--link=gitlab-ci-postgresql:postgresql --link=gitlab-ci-redis:redisio \
		--publish=10081:80 \
		--env='GITLAB_CI_PORT=10081' --env='GITLAB_URL=http://localhost:10080' \
		--env='GITLAB_APP_ID=xxx' --env='GITLAB_APP_SECRET=yyy' \
		${USER}/gitlab-ci:latest >/dev/null
	@echo "Please be patient. This could take a while..."
	@echo "GitLab CI will be available at http://localhost:10080"
	@echo "Type 'make logs' for the logs"

stop:
	@echo "Stopping gitlab-ci..."
	@docker stop gitlab-ci-demo >/dev/null
	@echo "Stopping redis..."
	@docker stop gitlab-ci-redis >/dev/null
	@echo "Stopping postgresql..."
	@docker stop gitlab-ci-postgresql >/dev/null
	@echo "Type 'make purge' to remove stopped containers"

purge: stop
	@echo "Removing stopped container..."
	@docker rm -v gitlab-ci-demo >/dev/null
	@docker rm -v gitlab-ci-redis >/dev/null
	@docker rm -v gitlab-ci-postgresql >/dev/null

logs:
	@docker logs -f gitlab-ci-demo
