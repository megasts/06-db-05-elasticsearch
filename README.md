# Домашнее задание к занятию 5. «Elasticsearch»

## Задача 1

В этом задании вы потренируетесь в:

- установке Elasticsearch,
- первоначальном конфигурировании Elasticsearch,
- запуске Elasticsearch в Docker.

Используя Docker-образ [centos:7](https://hub.docker.com/_/centos) как базовый и 
[документацию по установке и запуску Elastcisearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/targz.html):

- составьте Dockerfile-манифест для Elasticsearch,
- соберите Docker-образ и сделайте `push` в ваш docker.io-репозиторий,
- запустите контейнер из получившегося образа и выполните запрос пути `/` c хост-машины.

Требования к `elasticsearch.yml`:

- данные `path` должны сохраняться в `/var/lib`,
- имя ноды должно быть `netology_test`.

В ответе приведите:

- текст Dockerfile-манифеста,
- ссылку на образ в репозитории dockerhub,
- ответ `Elasticsearch` на запрос пути `/` в json-виде.

Подсказки:

- возможно, вам понадобится установка пакета perl-Digest-SHA для корректной работы пакета shasum,
- при сетевых проблемах внимательно изучите кластерные и сетевые настройки в elasticsearch.yml,
- при некоторых проблемах вам поможет Docker-директива ulimit,
- Elasticsearch в логах обычно описывает проблему и пути её решения.

Далее мы будем работать с этим экземпляром Elasticsearch.


### Ответ
---
- текст Dockerfile-манифеста:
```Dockerfile
FROM centos:7

COPY elasticsearch-7.17.22-linux-x86_64.tar.gz  /opt
COPY elasticsearch-7.17.22-linux-x86_64.tar.gz.sha512  /opt
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* &&\
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* &&\
    cd /opt && \
    groupadd elasticsearch && \
    useradd -c "elasticsearch" -g elasticsearch elasticsearch &&\
    yum update -y && yum -y install wget perl-Digest-SHA && \
    shasum -a 512 -c elasticsearch-7.17.22-linux-x86_64.tar.gz.sha512 && \
    tar -xzf elasticsearch-7.17.22-linux-x86_64.tar.gz && \
    rm elasticsearch-7.17.22-linux-x86_64.tar.gz elasticsearch-7.17.22-linux-x86_64.tar.gz.sha512 && \ 
    mkdir /var/lib/data && chmod -R 777 /var/lib/data && \
    chown -R elasticsearch:elasticsearch /opt/elasticsearch-7.17.22 && \
    yum -y remove wget perl-Digest-SHA && \
    yum clean all && \
    mkdir -p /var/lib/elasticsearch/ &&\
    chmod -R 777 /var/lib/elasticsearch/ &&\
    chgrp -R elasticsearch /var/lib/elasticsearch/

COPY ./config/elasticsearch.yml /opt/elasticsearch-7.17.22/config/elasticsearch.yml

USER elasticsearch
WORKDIR /var/lib/elasticsearch/
EXPOSE 9200 9300
CMD ["/opt/elasticsearch-7.17.22/bin/elasticsearch"]
```

- текст elasticsearch.yml:

```yml
node.name: netology_test
network.host: 0.0.0.0
path.data: /var/lib/elasticsearch/data/
path.logs: /var/lib/elasticsearch/logs/
path.repo: /var/lib/elasticsearch/snapshops/
network.publish_host: localhost
cluster.initial_master_nodes: 127.0.0.1
```
- ссылка на образ в репозитории dockerhub:
```
[https://hub.docker.com/repository/docker/megasts/elasticsearch/general](https://hub.docker.com/repository/docker/megasts/elasticsearch/general)
```
- ответ `Elasticsearch` на запрос пути `/` в json-виде:

![Screenshot1_1](https://github.com/megasts/06-db-05-elasticsearch/blob/main/img/Screenshot1_1.png)

---

## Задача 2

В этом задании вы научитесь:

- создавать и удалять индексы,
- изучать состояние кластера,
- обосновывать причину деградации доступности данных.

Ознакомьтесь с [документацией](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html) 
и добавьте в `Elasticsearch` 3 индекса в соответствии с таблицей:

| Имя | Количество реплик | Количество шард |
|-----|-------------------|-----------------|
| ind-1| 0 | 1 |
| ind-2 | 1 | 2 |
| ind-3 | 2 | 4 |

Получите список индексов и их статусов, используя API, и **приведите в ответе** на задание.

Получите состояние кластера `Elasticsearch`, используя API.

Как вы думаете, почему часть индексов и кластер находятся в состоянии yellow?

Удалите все индексы.

**Важно**

При проектировании кластера Elasticsearch нужно корректно рассчитывать количество реплик и шард,
иначе возможна потеря данных индексов, вплоть до полной, при деградации системы.

### Ответ

---
Список индексов и их статусов:

![Screenshot2_1](https://github.com/megasts/06-db-05-elasticsearch/blob/main/img/Screenshot2_1.png)

Состояние кластера `Elasticsearch`:

![Screenshot2_2](https://github.com/megasts/06-db-05-elasticsearch/blob/main/img/Screenshot2_2.png)

Состояние green только у первого индекса. У кластера и индексов ind-2 и ind-3 статус yellow потому, что в созданном кластере всего одна нода с одним шардом, реплики отсутствуют.

Удаление индексов:

![Screenshot2_3](https://github.com/megasts/06-db-05-elasticsearch/blob/main/img/Screenshot2_3.png)

---


## Задача 3

В этом задании вы научитесь:

- создавать бэкапы данных,
- восстанавливать индексы из бэкапов.

Создайте директорию `{путь до корневой директории с Elasticsearch в образе}/snapshots`.

Используя API, [зарегистрируйте](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-register-repository.html#snapshots-register-repository) 
эту директорию как `snapshot repository` c именем `netology_backup`.

**Приведите в ответе** запрос API и результат вызова API для создания репозитория.

Создайте индекс `test` с 0 реплик и 1 шардом и **приведите в ответе** список индексов.

[Создайте `snapshot`](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-take-snapshot.html) 
состояния кластера `Elasticsearch`.

**Приведите в ответе** список файлов в директории со `snapshot`.

Удалите индекс `test` и создайте индекс `test-2`. **Приведите в ответе** список индексов.

[Восстановите](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-restore-snapshot.html) состояние
кластера `Elasticsearch` из `snapshot`, созданного ранее. 

**Приведите в ответе** запрос к API восстановления и итоговый список индексов.

Подсказки:

- возможно, вам понадобится доработать `elasticsearch.yml` в части директивы `path.repo` и перезапустить `Elasticsearch`.

---
### Ответ

запрос API на регистрацию `snapshot repository` c именем `netology_backup`:

```sh
curl -X PUT "localhost:9200/_snapshot/netology_backup?verify=false&pretty" -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
    "location": "/var/lib/elasticsearch/snapshots/"
  }
}
'
```

результат вызова API для создания репозитория:

![Screenshot3_1](https://github.com/megasts/06-db-05-elasticsearch/blob/main/img/Screenshot3_1.png)

созданиe индекса `test` и список индексов после создания индекса `test`:

![Screenshot3_2](https://github.com/megasts/06-db-05-elasticsearch/blob/main/img/Screenshot3_2.png)

список файлов в директории со `snapshot` после создания снимка:

![Screenshot3_3](https://github.com/megasts/06-db-05-elasticsearch/blob/main/img/Screenshot3_3.png)

список индексов после удаления индекса `test` и создания индекса `test-2`:

![Screenshot3_4](https://github.com/megasts/06-db-05-elasticsearch/blob/main/img/Screenshot3_4.png)

запрос к API восстановления и итоговый список индексов:

![Screenshot3_5](https://github.com/megasts/06-db-05-elasticsearch/blob/main/img/Screenshot3_5.png)

---
### Как cдавать задание

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

---

