BEGIN WORK;
LOCK TABLE classes;

create table patron_classes (patron int references patrons(id), semester int references semesters(id), class int references classes(id), primary key (patron,semester,class));

alter table classes add column verified int references semesters(id);
alter table classes add column uid int references users(id);

COMMIT WORK;
