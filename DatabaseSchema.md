# Introduction #

TOME 3.0+ uses MYSql 5.1.37

Pre 3.0 uses PostgreSQL 8.1.10.

New developers can look here for information about what tables there are, what goes in each table, ...

# Details (3.0+) #
  * access
    * ID
    * pageName
    * minLevel
    * message
  * books
    * ID
    * libraryID
    * bookID
    * borrowerID
    * expires
    * expired
    * usable
    * comments
  * bookTypes
    * ID
    * title
    * isbn10
    * isbn13
    * author
    * edition
    * comments
  * borrowers
    * ID
    * email
    * name
    * valid
  * checkouts
    * ID
    * bookID
    * bookTypeID
    * tomekeeperID
    * libraryToID
    * libraryFromID
    * borrowerID
    * reserved
    * out
    * in
    * semester
    * comments
  * classbooks
    * ID
    * classID
    * bookID
    * verified
    * verifiedSemester
    * usable
    * comments
  * classes
    * ID
    * class
    * name
    * comments
  * errorLog
    * errorID
    * time
    * message
    * type
  * libraries
    * ID
    * name
    * interTOME
  * users
    * ID
    * username
    * password
    * password\_salt
    * permissions
    * active
    * lastUpdate
    * name
    * email
    * notifications
    * libraryID
    * secondContact
    * semester
    * firstLogin


# Details (pre 3.0) #
  * books - the general information about a textbook
    * isbn
    * title
    * author
    * edition
  * checkouts - a list of all checkouts (filled or not filled)
    * tomebook
    * semester
    * checkout
    * checkin
    * comments
    * library
    * uid
    * id
    * borrower
  * classbooks - associates textbooks with a certain class
  * classes - lists all the classes
  * db\_version - table to keep track of the database version for upgrading
  * libraries - lists all the libraries (floors) in the system
  * library\_access - associates a user with a library (this is really for users who are responsible for multiple libraries)
  * patrons - lists all the people that check out or donate books to Tome
  * reservations - tracks all reservations
  * semesters - list of the semesters
  * sessions - information for each session whenever anyone logs in
    * id (character-32; not null)
    * a\_session (text; not null)
  * tomebooks -
  * users - list of the tomekeepers
  * patron\_classes - this table isn't used at this time