# Docker MySQL 8
Docker MySQL8 with lean ubuntu 22.04 base.

## Usage
To pull latest image:

```sh
docker pull thuydx/mysql:8
```

To use in docker-compose
```yaml
# ./docker-compose.yml
version: '3'

services:
  db:
    image: thuydx/mysql:8
    container_name: db
    restart: unless-stopped
    tty: true
    ports:
      - "3306:3306"
    environment:
      MYSQL_DATABASE: dbname
      MYSQL_ROOT_PASSWORD: MYSQL_ROOT_PASSWORD
      SERVICE_TAGS: dev
      SERVICE_NAME: mysql
```
To use in docker-file
```Dockerfile
FROM thuydx/mysql:8
```