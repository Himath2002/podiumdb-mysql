# Contributing

Thank you for considering an improvement to PodiumDB.

## Development workflow

1. Create a focused branch from `main`.
2. Keep schema changes additive or document any migration impact.
3. Add an invariant or unit test for changed behaviour.
4. Run `make python-test` and `make static-test`.
5. With Docker available, run `make db-reset && make db-test`.
6. Open a pull request describing the motivation, design choice, and verification performed.

Use imperative, scoped commit messages such as `feat(schema): enforce event participant type`. Never commit credentials, personal records, database dumps, generated environments, or editor metadata.
