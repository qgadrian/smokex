[![Build Status](https://travis-ci.org/qgadrian/smokex.svg?branch=master)](https://travis-ci.org/qgadrian/smokex) [![Coverage Status](https://coveralls.io/repos/github/qgadrian/smokex/badge.svg?branch=master)](https://coveralls.io/github/qgadrian/smokex?branch=master) [![Deps Status](https://beta.hexfaktor.org/badge/all/github/qgadrian/smokex.svg)](https://beta.hexfaktor.org/github/qgadrian/smokex)

# Smokex

## Table of Contents

- [Overview](#overview)
  - [Features](#features)
- [Running](#running)
  - [Docker](#docker-image)
    - [Using an image](#using-an-image)
    - [Using Gitlab CI](#using-gitlab-ci)
  - [Standalone](#standalone)
- [Execution plan](#execution-plan)
  - [Detail](#detail)
- [Options](#options)
  - [File plan](#file-plan)
  - [Running args](#running-args)
- [Contributing](#contributing)
- [License](#license)

## Overview

Smokex is a simple tool to easily define and execute [smoke tests](https://en.wikipedia.org/wiki/Smoke_testing_(software)).

The goal of the tool is simplify the smoke tests process, as **anyone non-developer will be able to write tests**.

Excellent to test and **validate legacy backends**, but is also perfect to check and **verify deployments**, as it is very useful integrated into a **Continue Deployment pipeline**.

#### Features

  * YAML configuration
  * All HTTP methods supported
  * Assertions:
    * Status code
    * Headers present
    * Body response
  * Output with each request result
  * Quiet mode
  * Exit codes

## Running

### Docker

There is a [Docker image](https://hub.docker.com/r/qgadrian/smokex/) available to run Smokex easily.

#### Using an image

To use the Smokex Docker image you can create a Docker image and copy the execution file plan:

```Docker
FROM qgadrian/smokex:latest

ADD ./my_execution_plan.yml ./my_execution_plan.yml

CMD ["smokex", "./my_execution_plan.yml"]
```

#### Using Gitlab CI

If you are using [Gitlab CI](https://about.gitlab.com/features/gitlab-ci-cd/), it will as easy as create a job to run smokex.

```yaml
smoke-tests:
  image: qgadrian/smokex:latest
  stage: a-test-stage
  script:
    - smokex ./my_execution_plan.yml
```

### Standalone

Build:

```elixir
mix deps.get
mix build
```

Run:
```bash
./smokex ./examples/sucess_example.yml
```

**Execution with console output**

<img src="http://i.imgur.com/n3T6inz.png"/>

**Execution with JSON output**

<img src="https://i.imgur.com/tAShkVj.png?1"/>

## Execution plan

The smoke test execution plan has the following format:

```yaml
- http_method: #get, post, put...
    host: # Host URL, for example www.google.com
    headers: # Request headers
      header_1: "value"
    query: # URL query params
      param_1: "value"
    body: # Request body params
      param_1: "value"
    expect: # Expected results
      status_code: # Expected response status code
      headers: # Expected headers
        header_1: "value"
      body: # Expected body, only JSON and String supported
        key: "expected_value"
    save_from_response: # Save a JSON path value to a named variable to reuse its value
      - variable_name: "my_session_token"
        json_path: "session.token"
    options:
      timeout: # Time in milliseconds until the request will fail
```

### Detail

* #### host

  The host that will be used in the request.

* #### headers

  Headers that will be sent in the requests.

* #### query

  [Query params](https://en.wikipedia.org/wiki/Query_string) sent within the URL.

* #### body

  The body of the request.

* #### expect

  The following term will be assertions over the host's response.

  * ##### status code

    Status code of the response, for example `200` for an HTTP OK.

  * ##### headers

    List of headers and their value that will be sent in the response.

  * ##### body

    Body contained in the response, which has to be equals the asserted.

    It supports a JSON body or a single string.

* #### save from response

  Saves to a variable the value of a given [JSON path](https://github.com/json-path/JsonPath).

  A saved variable can be used in any request by writing its name: `${var_name}`.

  Example:

  ```yaml
  - post: # returns { session: { token: "a_session_token" } }
      host: "https://my_host/login"
      body:
        username: "foo"
        password: "bar"
      save_from_response:
        - variable_name: "session_token"
          json_path: "session.token"
  - get:
      host: "https://my_host/protected"
      headers:
        authorization: "${session_token}"
      expect:
        status_code: 200
  ```

  ###### **This feature is WIP and only supports child notation**

* #### options

  * ##### timeout

    The amount of time the response until the request will be consider as failed.

### Examples

A working example can be found in the `examples` folder.

## Options

### File plan

It's possible to give specific options for each request:

```yaml
- get:
    host: "http://www.google.com"
    expect:
      status_code: 200
    options:
      timeout: 2300
```

### Running args

Smokex **requires a path to a yaml file** with a list of steps to execute the smoke calls.

Smokex accepts the following options:

* `-t --timeout`  – Sets a timeout for all requests in the execution plan
* `-q --quiet`    – Excludes steps output information
* `-o --output`   – Execution output format (default console): [console | json]
* `-h --help`     – Print help

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/qgadrian/SmokexClient.

## License

This software is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
