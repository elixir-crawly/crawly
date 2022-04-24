
id = $(shell echo $RANDOM | md5sum | head -c 6; echo;)

start:
	docker-compose build --no-rm  --parallel    -q
	docker-compose up -d  --quiet-pull   --remove-orphans
	docker-compose logs -f --tail=100
tail:
	docker-compose logs -f --tail=100

stop:
	docker-compose down


iex.req:
	docker-compose exec req bash -c "iex --remsh requestor --sname req${id}  --cookie dev" 
iex.pro:
	docker-compose exec pro bash -c "iex --remsh processor --sname pro${id}  --cookie dev" 