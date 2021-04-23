# Docker Deployment

This directory contains an example deployment of Boundary using docker-compose and Terraform. The lab environment is meant to accompany the Hashicorp Learn [Boundary target-aware workers tutorial](https://learn.hashicorp.com/tutorials/boundary/target-aware-workers).

In this example, Boundary is deployed using the [hashicorp/boundary](https://hub.docker.com/r/hashicorp/boundary) Dockerhub image. The Boundary service ports are forwarded to the host machine to mimic being in a "public" network. Boundary is provisioned via Terraform to include targets for popular databases:

- postgres
- redis
- mysql

All of these targets are on containers that are not port forwarded to the host machine in order to mimic them residing in a private network. Boundary is configured to reach these targets via Docker DNS (domain names defined by their service name in docker-compose). Clients can reach these targets via Boundary, and an example is given below using the redis-cli.

## Getting Started 

There is a helper script called `run` in this directory. You can use this script to deploy, login, and cleanup.

Start the docker-compose deployment:

```bash
./run all
```

To login your Boundary CLI:

```bash
./run login
```

To stop all containers and start from scratch:

```bash
./run cleanup
```

Login to the UI:
  - Open browser to localhost:9200
  - Login Name: user1
  - Password: password
  - Auth method ID: find this in the UI when selecting the auth method or from TF output

```bash
$ boundary authenticate password -login-name user1 -password password -auth-method-id <get_from_console_or_tf>

Authentication information:
  Account ID:      apw_gAE1rrpnG2
  Auth Method ID:  ampw_Qrwp0l7UH4
  Expiration Time: Fri, 06 Nov 2020 07:17:01 PST
  Token:           at_NXiLK0izep_s14YkrMC6A4MajKyPekeqTTyqoFSg3cytC4cP8sssBRe5R8cXoerLkG7vmRYAY5q1Ksfew3JcxWSevNosoKarbkWABuBWPWZyQeUM1iEoFcz6uXLEyn1uVSKek7g9omERHrFs
```

## Connect to Private Redis

Once the deployment is live, you can connect to the containers (assuming their clients are
installed on your host system). For example, we'll use [redis-cli](https://redis.io/topics/rediscli) to ping the Redis container via Boundary:

```bash
$ boundary connect -exec redis-cli -target-id ttcp_Mgvxjg8pjP -- -p {{boundary.port}} ping
PONG
```

Explore the other containers such as Postgres and Mysql (default passwords are set via env vars in the docker-compose.yml file).

```bash
$ boundary connect postgres -target-name postgres -target-scope-name databases -username postgres -- -l
Password for user postgres:
                                 List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges
-----------+----------+----------+------------+------------+-----------------------
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 test1     | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
(4 rows)
```

```bash
$ boundary connect postgres -target-name postgres -target-scope-name databases -username postgres -- -l
psql: error: server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
```

The mysql target is purposefully misconfigured with worker filters and corrected in the tutorial.