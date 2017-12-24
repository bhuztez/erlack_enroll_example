-module(erlack_enroll_example).

-compile({parse_transform,
          erlack_url_dispatch}).
-compile({parse_transform,
          erlack_db}).

-export([start/0, url_reverse/2, handle/0, url_dispatch/1]).

-pattern(
   { integer,
     "[0-9]+",
     {erlang, binary_to_integer},
     {erlang, integer_to_binary}
   }).

-dispatch({root, "show/{id:integer}", {endpoint, show}}).
-dispatch({root, "intersection/{x:integer}/{y:integer}", {endpoint, intersection}}).
-dispatch({root, "enroll/{s:integer}/{c:integer}", {endpoint, enroll}}).

start() ->
    start(8000).

start(Port) ->
    erlack_debug_server:start(Port, [], {?MODULE, handle, []}).

not_found() ->
    { response,
      404,
      #{<<"Content-Type">> => <<"text/plain; charset=utf-8">>},
      <<"Not Found">>
    }.

json_response(Code, Body) ->
    { response,
      Code,
      #{<<"Content-Type">> => <<"application/json">>},
      jsone:encode(Body)
    }.

handle() ->
    ecgi:apply_handler(
      lists:foldr(
        fun erlack_middleware:wrap/2,
        fun handle_request/0,
        [{erlack_reason_phrase, middleware,[]},
         {erlack_content_length, middleware,[]},
         {erlack_routing, middleware, [?MODULE, fun not_found/0]}])).

handle_request() ->
    {ok, DB} = connect_db(),
    try
        {ok, _, _} = epgsql:squery(DB, "BEGIN"),
        handle_request(DB, get(<<"REQUEST_METHOD">>), get(erlack_endpoint), get(erlack_args))
    after
        epgsql:close(DB)
    end.

connect_db() ->
    epgsql:connect(
      "127.0.0.1",
      "erlack", "",
      [{database, "erlack"}]
     ).


handle_request(DB, <<"GET">>, show, #{id := ID}) ->
    ClassTimes =
        erlack_db:select(
          DB,
          [#{course => Course,
             time => ClassTime,
             teacher => Teacher
            }
           || #{student_id := StudentID, course_id := CourseID} <- from(erlack_enroll),
              #{name := Course, teacher_id := TeacherID} <- join(erlack_course, c(course_id) == CourseID),
              #{name := Teacher} <- join(erlack_teacher, c(teacher_id) == TeacherID),
              #{class_time := ClassTime} <- join(erlack_classtime, c(course_id) == CourseID),
              StudentID == ID,
              order_by(asc(ClassTime))
          ]
         ),
    json_response(200, ClassTimes);
handle_request(DB, <<"GET">>, intersection, #{x := X, y := Y}) ->
    Courses =
        erlack_db:select(
          DB,
          [ CX
            || #{student_id := XID, course_id := CX} <- from(erlack_enroll),
               #{student_id := YID, course_id := CY} <- from(erlack_enroll),
               X == XID, Y == YID, CX == CY
          ]
         ),
    json_response(200, Courses);
handle_request(DB, <<"PUT">>, enroll, #{s := S, c := C}) ->
    {ok, _, Rows} =
        epgsql:equery(
          DB,
          "SELECT student_id FROM erlack_student WHERE student_id = $1 FOR UPDATE",
          [S]),
    case Rows of
        [] ->
            json_response(404, <<"student not found">>);
        _ ->
            case epgsql:equery(
                   DB,
                   "INSERT INTO erlack_enroll(student_id, course_id) VALUES ($1,$2) ON CONFLICT DO NOTHING",
                   [S,C])
            of
                {ok, _} ->
                    [Count] =
                        erlack_db:select(
                          DB,
                          [ Count
                            || #{student_id := StudentID, enroll_id := ID} <- from(erlack_enroll),
                               Count <- [count(ID)],
                               StudentID == S
                          ]
                         ),

                    if Count > 5 ->
                            json_response(403, <<"cannot enroll no more than 5 courses">>);
                       true ->
                            case erlack_db:select(
                                   DB,
                                   [ {ID1, ID2}
                                     || #{student_id := S2, course_id := C1} <- from(erlack_enroll),
                                        #{student_id := S1, course_id := C2} <- from(erlack_enroll),
                                        #{classtime_id := ID1, class_time := Time1, course_id := CC1} <- from(erlack_classtime),
                                        #{classtime_id := ID2, class_time := Time2, course_id := CC2} <- from(erlack_classtime),
                                        CC1 == C1, CC2 == C2, ID2 > ID1, range_overlap(Time1, Time2),
                                        S1 == S, S2 == S
                                   ])
                            of
                                [] ->
                                    {ok, _} =
                                        epgsql:equery(
                                          DB,
                                          "UPDATE erlack_student SET enroll_count = $1 WHERE student_id = $2",
                                      [Count, S]),
                                    {ok, _, _} = epgsql:squery(DB, "COMMIT"),
                                    json_response(200, <<"ok">>);
                                _ ->
                                    json_response(403, <<"course time conflict">>)
                            end
                    end;
                {error, _} ->
                    json_response(404, <<"course not found">>)
            end
    end.
