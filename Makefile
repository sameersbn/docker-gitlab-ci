all: help

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

quickstart:
	@echo "Starting gitlab-ci..."
	@docker run --name='gitlab-ci-demo' -d \
		-p 10080:80 --link gitlab:gitlab \
		-v /var/run/docker.sock:/run/docker.sock \
		-v $(shell which docker):/bin/docker \
		${USER}/gitlab-ci:latest >/dev/null
	@echo "Please be patient. This could take a while..."
	@echo "GitLab CI will be available at http://localhost:10080"
	@echo "Type 'make logs' for the logs"

stop:
	@echo "Stopping gitlab-ci..."
	@docker stop gitlab-ci-demo >/dev/null

purge: stop
	@echo "Removing stopped container..."
	@docker rm gitlab-ci-demo >/dev/null

logs:
	@docker logs -f gitlab-ci-demo
