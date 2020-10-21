# Описание Dockerfile для Drone
Данный файл брался c оффициального git репозитория проекта Drone
Образ базируется на google/golang
```
FROM google/golang
```
Задание переменной окружения DRONE_SERVER_PORT
```
ENV DRONE_SERVER_PORT :80
```
Добавление всего git-репозитория в контейнер
```
ADD . /gopath/src/github.com/drone/drone/
```
Рабочий каталог внутри контейнера
```
WORKDIR /gopath/src/github.com/drone/drone
```
Установка зависимостей
```
RUN apt-get update
RUN apt-get -y install zip libsqlite3-dev sqlite3 1> /dev/null 2> /dev/null
RUN make deps build embed install
```
Открытие порта
```
EXPOSE 80
```
Задание переменной окружения DRONE_DATABASE_DATASOURCE и DRONE_DATABASE_DRIVER
```
ENV DRONE_DATABASE_DATASOURCE /var/lib/drone/drone.sqlite
ENV DRONE_DATABASE_DRIVER sqlite3
```
Указание хранилища
```
VOLUME ["/var/lib/drone"]
```
Указание входной точки 
```
ENTRYPOINT ["/usr/local/bin/droned"]
```