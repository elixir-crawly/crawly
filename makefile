


start:
	docker-compose up -d
	docker-compose logs -f

restart:
	docker-compose restart
	docker-compose logs -f
