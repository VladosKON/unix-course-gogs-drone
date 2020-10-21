## Установка на Debian:

docker-compose up

### Конфигурация Gogs:

http://localhost:3000

- Использовать MySQL:
  - Host: mysql:3306
  - User: gogs
  - Password: gogs
  - Database Name: gogs
- Поставить в 'Application URL' hostname (Узнать командой `hostname`) и порт 3000 (`http://hostname:3000/`)
- Создать пользователя админа

### Конфигурация Drone:

http://localhost:8000

Использовать username/password созданный в Gogs

#### Удалить все данные:

- sudo rm -rf gogs/ drone/ mysql/
- docker system prune -a
