# osTicket com Docker

Este repositório agora inclui um ambiente local com `docker compose` para subir o osTicket com `PHP 8.4 + Apache` e `MariaDB 10.11`.

## Como subir

1. Copie o arquivo de exemplo:

   ```bash
   cp .env.docker.example .env.docker
   ```

2. Suba os containers:

   ```bash
   docker compose --env-file .env.docker up --build
   ```

3. Abra:

   ```text
   http://localhost:8080/setup/
   ```

## Banco para o instalador

Use os valores abaixo no instalador web, a menos que tenha alterado o `.env.docker`:

- Host: `db`
- Database: `osticket`
- User: `osticket`
- Password: `osticket`

## Como funciona

- O container `web` instala as extensoes PHP exigidas pelo projeto, incluindo `imap`.
- O container tambem habilita `APCu` para melhorar cache e desempenho.
- No startup, o entrypoint executa `php manage.php deploy --setup /var/www/html`.
- O codigo-fonte local e montado em `/srv/osticket-src` apenas para servir de origem ao `deploy`.
- O deploy final fica persistido no volume `osticket-app`.
- O banco fica persistido no volume `osticket-db`.

## Atualizando o codigo

Por padrao, o container reaplica o `deploy` a cada start com `OSTICKET_DEPLOY_ON_START=1`. Se quiser desligar esse comportamento, ajuste a variavel no `.env.docker`.

## Pos-instalacao

Depois que a instalacao terminar, vale remover a pasta `setup` do volume implantado e travar o arquivo de configuracao:

```bash
docker compose exec web rm -rf /var/www/html/setup
docker compose exec web chmod 0644 /var/www/html/include/ost-config.php
```
