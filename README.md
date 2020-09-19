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
heroku run "eval \"Smokex.Release.create_database()\""
heroku run "eval \"Smokex.Release.migrate()\""
```

> We use a pool size of `2` with an application configured with a pool size of
> `18`, so we will avoid issues with database connections. If you still have
> problems try to update the `POOL_SIZE` environment variable to a lower value
> and try again.

* Enable datadog metrics:

```bash
heroku drains:add 'https://http-intake.logs.datadoghq.com/v1/input/<DD_API_KEY>?ddsource=heroku&service=smokex&host=<HOST>' -a smokex
```

#### Docker containers

* Login into Heroku registry `heroku container:login`
* Build and push an image `heroku container:push web`

### Gigalixir

#### Working with umbrella projects

* [ ] Add the phoenix relative path to the buildpack, [see
    example](https://github.com/gjaldon/heroku-buildpack-phoenix-static#configuration)
* [ ] [Set which release
    profile](https://gigalixir.readthedocs.io/en/latest/config.html#gigalixir-release-options) should be used
* [ ] Run migration `gigalixir ps:migrate` with `--migration_app_name` flag

#### Logs

```bash
heroku drains:add 'https://http-intake.logs.datadoghq.com/v1/input/<DD_APY_KEY>?ddsource=heroku&service=smokex&host=gigalixir' -a smokex

```

## Development

### Run a release locally

There are multiple environment variables that are expected to be set in order to
run a release:

```bash
SECRET_KEY_BASE=kGXrNEYUVAm2zOpB8UQMRfK+JkDnqFcH4WOcM8nYApN/fMWVJoQPMGqrUTwv15w5 DATABASE_HOSTNAME=postgres-free-tier-1.gigalixir.com DATABASE_USERNAME=test DATABASE_PASSWORD=test DATABASE_NAME=test PORT=4000 POOL_SIZE=1 DATABASE_URL="" STRIPE_API_KEY="" STRIPE_SIGNING_SECRET="" _build/prod/rel/smokex/bin/smokex start_iex
```

### Need to know

* The Stripe button to buy a subscription requires environment variables to be
    configured or it will throw the `unexpected item shape` error if not.
* The Slack integration also requires a runtime configuration therefore it will
    fail locally. Also, the redirection done by Slack is to production host.

## Random storm ideas & stuff

### Why this product?

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

### Experience situations where Smokex tests were needed

* Empty deployment with health check workng ok but actual endpoints were all
    failing
* App requires some environment variables set before start, they were available
    on deployment so all went good. After some days the app got restarted but the
    variables were not available anymore (were managed by a third party service),
    entering in a crash loop and no one noticing.

### Uses cases (smoke tests & HTTP automation)

* Schedule a HTTP request to keep Heroku instances up.
* Send a ping request to ensure a system is reachable.
* Retrieve a information from currency prices and send it to your server to get update value #nocode

## MVP

* [x] Cancel user subscriptions (implemented, needs testing)
* [x] Show code examples page
* [x] File upload VS YAML copy and paste (uses the WYSIWYG editor)
* [x] Create table with Stripe subscriptions
* [x] Generate the Docker image and deploy to Heroku
* [x] Setup Sentry errors
* [x] Support variables concat on host names or any other keys
* [x] Setup Datadog logs & monitoring
* [x] Setup domain
* [x] Setup Oban
* [x] Start and trigger Oban jobs
* [x] Create page to document the YAML templates
* [x] No validation message when creating a plan definition with an empty
    content `save_from_response` won't return any details in the request error.
* [x] Persist scheduled jobs or respawn them on node restart (uses a
    `start_phase` to spawn the schedules
* [x] Subscribe to all user plan definitions and executions to update the proper view
* [x] Add execution limit to scheduled jobs
* [x] Password reset view
* [x] Emailing for confirm account an password reset
* [x] Add YAML parse validation to plan definition new/edit
* [x] Enable production Stripe
* [x] Increase timeout config to 10 seconds
* [x] Ensure all the important metrics are properly setup
* [ ] Fix CTA buttons when the liveview is already loaded
* [x] Improve the top bar links and navigation.
* [x] Improve subscription information shown
* [x] If no current subscription in billing view show info and CTA

### Post release

* [ ] Add view to promote "beta free access", ideally toggleable by
    configuration
* [x] Create welcome page with introduction to Smokex
* [ ] Mail the welcome content to registered users
* [x] Add terms and conditions links to footer
* [ ] Create a blog page with some explanations about what can do (?)
* [x] Avoid make the cron sentence mandatory
* [x] First SEO steps (robots, sitemap..)
* [x] Slack notifications
  * [ ] Seems that when using buttons Slack expects a callback to be handled: https://api.slack.com/interactivity/handling#acknowledgment_response
* [ ] Check: missing logs on worker processes?
* [ ] Listen to tab event on the yaml editor to avoid jumping out and screwing
    with the browser

### Nice to have (next prio)

* [ ] Hide `load more` button when reached end of page
* [ ] Allow set custom timeout per each step
* [ ] Add button to view plan definition from execution view
* [ ] Delete plans
* [~] Generate digest on Docker build. UPDATE: seems that not working 100%
* [ ] Create environment variables for configurations, for example
    `apps/smokex/lib/smokex/users.ex`
* [ ] Use https://github.com/ispirata/exjsonpath/ to get data from JSON
* [x] Create organizations model (mind some logic needs to be replaced, for
    example `Limits`)
* [ ] Add `finished with error` state?
* [ ] Add the reason details of failed request. For example, a wrong ?????
* [ ] Add metadata plugs
* [ ] Connect to Github and auto create a plan based on the files under `.smokex`
* [~] Allow remote console access on Heroku (see
    https://medium.com/@karmajunkie/distributed-elixir-on-heroku-59b691d9868e
    and https://github.com/phoenixframework/phoenix/issues/2558). UPDATE: Kid of
    working with `docker entrypoint` but it's a new node and not connected to
    other container
* [ ] Proper YAML linting and format check. Ideally on the WYSIWYG editor

### Nice to have (very low prio)

* [ ] Measure request time per plan step and show a graph view for performance
* [ ] Add Sendgrid integration to allow sending email using the user API KEY
* [ ] Migrate to a distributed application, so far it is a single instance
* [ ] Provide API endpoint to start an execution. Mind this will need an API KEY (for that, for example see https://github.com/danschultzer/pow/issues/176). UPDATE: low prio because of Github integration
* [ ] Provide interface or module to manage the scheduled jobs (aka `Smokex.PlanDefinitions.Scheduler.jobs`). UPDATE: low prio since database provides some info already
* [ ] Improve the scheduled jobs management, by either persisting them or
    finding a better solution than using a `start_phase`. UPDATE: low prio until
    there is more workload
* [ ] Run datadog agent with [supervisord](http://supervisord.org/), right now
    is a async bash process (see `docker-entrypoint.sh`)

#### Distributed application

The current application is a single monolith, although it uses umbrella
applications to provide _microservices_.

The goal is release several application instances with role _worker_ that will
be executing the actions triggered by an orchestrator, which can be considered
as _producer_.

Considerations for distributed architecture:

* We are using `quantum` to schedule jobs, it can use mnesia to store the
    schedule jobs but keep in mind the network partition problems. This
    application uses Cachex already so consider implementing a backend for it
    (https://hexdocs.pm/quantum/configuration.html#persistent-storage). To solve
    this problem we can have a _producer_ node that will be handling the
    schedule jobs and when the node taking the role starts just puts all the
    scheduled jobs in a cache, so everytime the _producer_ node dies the new one
    will regenerate the state.
* Oban might need distributed extra configurations
