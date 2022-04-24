


start:
	docker-compose build --no-rm  --parallel    -q
	docker-compose up -d  --quiet-pull   --remove-orphans
	docker-compose logs -f --tail=100
tail:
	docker-compose logs -f --tail=100

stop:
	docker-compose down