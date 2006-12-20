BEGIN WORK;
LOCK TABLE patron_classes,classes;

alter table classes alter column id type text;
ALTER TABLE patron_classes alter column class type text;

COMMIT WORK;
