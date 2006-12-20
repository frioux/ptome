BEGIN WORK;

create table patron_classes (patron int references patrons(id), semester int references semesters(id), class int references classes(id), primary key (patron,semester,class));

COMMIT WORK;
