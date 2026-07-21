PYTHON ?= .venv/bin/python

.PHONY: install python-test static-test db-up db-down db-reset db-test analytics verify

install:
	$(PYTHON) -m pip install .

python-test:
	PYTHONPATH=src $(PYTHON) -m unittest discover -s tests -v

static-test:
	PYTHONPATH=src $(PYTHON) -m compileall -q src tests

db-up:
	docker compose up -d --wait

db-down:
	docker compose down

db-reset:
	docker compose down -v
	docker compose up -d --wait

db-test:
	docker compose exec -T mysql sh -c 'mysql -u"$$MYSQL_USER" -p"$$MYSQL_PASSWORD" "$$MYSQL_DATABASE"' < sql/tests/invariants.sql

analytics:
	docker compose exec -T mysql sh -c 'mysql -u"$$MYSQL_USER" -p"$$MYSQL_PASSWORD" "$$MYSQL_DATABASE"' < sql/analytics/queries.sql

verify: python-test static-test db-test
