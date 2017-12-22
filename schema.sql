CREATE TABLE erlack_teacher (
  teacher_id BIGSERIAL PRIMARY KEY,
  name VARCHAR(200) UNIQUE NOT NULL
);

CREATE TABLE erlack_course (
  course_id BIGSERIAL PRIMARY KEY,
  name VARCHAR(200) UNIQUE NOT NULL,
  teacher_id BIGINT REFERENCES erlack_teacher
);

CREATE TABLE erlack_classtime (
  classtime_id BIGSERIAL PRIMARY KEY,
  course_id BIGINT REFERENCES erlack_course,
  class_time TSRANGE
);

CREATE TABLE erlack_student (
  student_id BIGSERIAL PRIMARY KEY,
  name VARCHAR(200) UNIQUE NOT NULL,
  enroll_count BIGINT
);

CREATE TABLE erlack_enroll (
  enroll_id BIGSERIAL PRIMARY KEY,
  student_id BIGINT REFERENCES erlack_student,
  course_id BIGINT REFERENCES erlack_course,
  UNIQUE(student_id, course_id)
);

INSERT INTO erlack_teacher VALUES (1,'Jack');
INSERT INTO erlack_teacher VALUES (2,'John');

INSERT INTO erlack_student VALUES (1,'Tim',0);
INSERT INTO erlack_student VALUES (2,'Tom',0);

INSERT INTO erlack_course VALUES (1, 'Course A', 1);
INSERT INTO erlack_course VALUES (2, 'Course B', 1);
INSERT INTO erlack_course VALUES (3, 'Course C', 2);
INSERT INTO erlack_course VALUES (4, 'Course D', 2);

INSERT INTO erlack_classtime VALUES (1, 1, '[2010-01-01 9:30, 2010-01-01 10:30]'::tsrange);
INSERT INTO erlack_classtime VALUES (2, 1, '[2010-01-01 13:30, 2010-01-01 14:30]'::tsrange);
INSERT INTO erlack_classtime VALUES (3, 2, '[2010-01-01 16:00, 2010-01-01 17:00]'::tsrange);
INSERT INTO erlack_classtime VALUES (4, 3, '[2010-01-01 10:00, 2010-01-01 11:00]'::tsrange);
INSERT INTO erlack_classtime VALUES (5, 4, '[2010-01-01 14:45, 2010-01-01 15:45]'::tsrange);
