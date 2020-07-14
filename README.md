# Smokex.Umbrella

## Deployment

### Gigalixir

#### Working with umbrella projects

* [ ] Add the phoenix relative path to the buildpack, [see
    example](https://github.com/gjaldon/heroku-buildpack-phoenix-static#configuration)
* [ ] [Set which release
    profile](https://gigalixir.readthedocs.io/en/latest/config.html#gigalixir-release-options) should be used
* [ ] Run migration `gigalixir ps:migrate` with `--migration_app_name` flag

## Why?

* Not everybody has CI pipelines
* You don't want to mix CI executions with smoke testing
* You want a clear way to identify downtimes, errors...
* Monitor any legacy project with little effort
* But also easily run smoke tests on a new project to validate deployments
* Can give access to third parties without to have access to source code o
    sensitive tools
* Won't require technical knowledge
* Won't be coupled to any testing library and making changes transparent to the
    repo
