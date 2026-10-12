# sql-playground
Sandbox repository to learn SQL features and concepts.

## SQL guide

A quick-review guide to SQL, from the basics to window functions, recursive CTEs, indexes and transaction isolation. Each section is tagged with its level and importance, and it ends with exercises with solutions.

Read it all in one file, or one section at a time:

|            | Single file                        | One file per section                  |
|------------|------------------------------------|---------------------------------------|
| 🇬🇧 English | [sql-guide.md](sql-guide.md)       | [sections/en/](sections/en/README.md) |
| 🇪🇸 Español | [sql-guide-es.md](sql-guide-es.md) | [sections/es/](sections/es/README.md) |

## Practice with real databases

With [Docker](https://www.docker.com/) and Node 22 or later (no `npm install` needed):

```bash
npm run db:up      # start MySQL 8.4 and PostgreSQL 17
npm run db:load    # load the example tables (customers/orders and clientes/pedidos)
npm run db:down    # stop them and delete their data
```

Connect with any client to `localhost` (MySQL on port 3306, PostgreSQL on 5432), user `root` / `postgres`, password `playground`, database `playground`. Or open a shell inside the container:

```bash
docker compose exec mysql mysql -uroot -pplayground playground
docker compose exec postgres psql -U postgres -d playground
```

## Contributing

- Edit only `sql-guide.md` and `sql-guide-es.md`. Everything under `sections/` is generated from them: regenerate with `npm run build:sections`. `npm run check:sections` tells you if `sections/` is out of date.
- The guide's SQL is checked against MySQL and PostgreSQL. `verify/cases/` holds the examples of each section and `verify/expected/` the reviewed output; the exercises are taken straight from the guides. With the databases running (`npm run db:up`), run `npm run verify:sql`.
  - If you change a section's SQL, the check tells you which case to review. Update the case if needed, then save the new output with `npm run verify:sql -- --update` and review it with `git diff verify/expected`.
- GitHub runs the tests, the sections check and the SQL check on every push.

## License

© 2026 Anakku-Shell. Licensed under [CC BY 4.0](LICENSE): you can share and adapt this material, as long as you give credit.
