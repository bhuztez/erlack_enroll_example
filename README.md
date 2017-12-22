# erlack_enroll_example

## Requirements

ansible
bash
erlang
postgresql
supervisord

## Run

```
$ git clone git://github.com/bhuztez/erlack_enroll_example
$ cd erlack_enroll_example
$ ./bin/develop start
$ ./bin/psql < schema.sql
$ rebar3 shell
1> erlack_enroll_example:start().
```

```
$ curl -XPUT 'http://127.0.0.1:8000/enroll/1/1'
"ok"
$ curl 'http://127.0.0.1:8000/show/1' | json_reformat
[
    {
        "course": "Course A",
        "teacher": "Jack",
        "time": "[\"2010-01-01 09:30:00\",\"2010-01-01 10:30:00\"]"
    },
    {
        "course": "Course A",
        "teacher": "Jack",
        "time": "[\"2010-01-01 13:30:00\",\"2010-01-01 14:30:00\"]"
    }
]
$ curl 'http://127.0.0.1:8000/intersection/1/2'
[]
```
