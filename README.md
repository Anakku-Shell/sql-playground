# sql-playground
Sandbox repository to learn SQL features and concepts.

## SQL guide

A quick-review guide to SQL, from the basics to window functions, recursive CTEs, indexes and transaction isolation. Each section is tagged with its level and importance, and it ends with exercises with solutions.

Read it all in one file, or one section at a time:

|            | Single file                        | One file per section                  |
|------------|------------------------------------|---------------------------------------|
| 🇬🇧 English | [sql-guide.md](sql-guide.md)       | [sections/en/](sections/en/README.md) |
| 🇪🇸 Español | [sql-guide-es.md](sql-guide-es.md) | [sections/es/](sections/es/README.md) |

## Contributing

- Edit only `sql-guide.md` and `sql-guide-es.md`. Everything under `sections/` is generated from them.
- After editing, regenerate with `npm run build:sections` (Node 22 or later; no `npm install` needed). `npm run check:sections` tells you if `sections/` is out of date.

## License

[CC BY 4.0](LICENSE): you can share and adapt this material, as long as you give credit.
