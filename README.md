# Smokex.Umbrella

## Deployment

## Heroku

* Install hero client

```bash
brew tap heroku/brew && brew install heroku
```

* Install the Elixir and Phoenix buildpacks in the application (skip the `-a` to create a new
    one)

```bash
heroku buildpacks:set hashnuke/elixir -a smokex
heroku buildpacks:add https://github.com/gjaldon/heroku-buildpack-phoenix-static.git
```

> Remember to defined the build pack config in the project root path.

* Add remote branch to deploy on heroku (not mandatory, you can also connect
    Github from the Heroku dashboard)

```bash
heroku git:remote -a smokex
git push heroku master
```

* **To use releases** add the following to the elixir buildpack

```buildpack
release=true
```

And create a proc file with

```procfile
web: _build/prod/rel/smokex/bin/smokex start
```

* Add runtime configurations

```bash
heroku config:set PORT=4000
...
```

* Run migrations

> Heroku only deployes the release to the Dyno, so the module `Smokex.Release`
> needs to be used in order to run the migrations.


```bash
heroku run "POOL_SIZE=2 _build/prod/rel/smokex/bin/smokex eval \"Smokex.Release.create_database()\""
heroku run "POOL_SIZE=2 _build/prod/rel/smokex/bin/smokex eval \"Smokex.Release.migrate()\""
```

> We use a pool size of `2` with an application configured with a pool size of
> `18`, so we will avoid issues with database connections.

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
