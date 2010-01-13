<?php
    function getSemester($semester) {
        $time = strtotime($semester);
        $year = (int)date("Y", $time);
        $tmp = date("n", $time);
        if($tmp <= 5) {
            $ret = .25;
        } elseif($tmp <= 8) {
            $ret = .5;
        } else {
            $ret = .75;
        }
        return $year+$ret;
    }

    function findDate($semester) {
         $semester = explode(" ", $semester);
         $semester[0] = substr($semester[0], 0, -1);
         if($semester[1] == "Summer") {
            // Date July 4th
            return date('Y-m-d', mktime(0, 0, 0, 7, 4, (int) $semester[0]));
         } else if($semester[1] == "Fall") {
            // Date November 5th
            return date('Y-m-d', mktime(0, 0, 0, 11, 5, (int) $semester[0]));
         } else {
            /// Date February 13th
            return date('Y-m-d', mktime(0, 0, 0, 2, 13, (int) $semester[0]));
         }
    }

    function makeFloat($semester)
    {
       $semester = explode(" ", $semester);
       $semester[0] = substr($semester[0], 0, -1);
       if($semester[1] == "Spring")
       {
          $float = (float) $semester[0];
          $float = $float + 0.25;
       }
       else if($semester[1] == "Summer")
       {
          $float = (float) $semester[0];
          $float = $float + 0.5;
       }
       else if($semester[1] == "Fall")
       {
          $float = (float) $semester[0];
          $float = $float + 0.75;
       }

       return $float;
    }

    $path = "../../";
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");

    //migrate the old data
    $data = file_get_contents("tomedb-hourly.sql", "r");
    $data = preg_replace("/.*?--\s*Data for Name.*?(\r?\n)(?=COPY books)/s", "", $data, 1);
    $data = preg_split("/\\\\\\.\r?\n/", $data);
    array_pop($data);

    //id, name, current
    $lines = preg_split("/\r?\n/", $data[10]);
    $lines = array_slice($lines, 7);
    array_pop($lines);
    foreach($lines as $line) {
        $line = explode("\t", $line);
        $semesters[$line[0]] = findDate($line[1]);
        $semesterF[$line[0]] = makeFloat($line[1]);
    }

    //id, name, comments, verified, uid
    $count = 0;
    $out = 'INSERT INTO `classes` (`class`, `name`, `comments`) VALUES'."\n";
    $lines = preg_split("/\r?\n/", $data[3]);
    $lines = array_slice($lines, 7);
    array_pop($lines);
    foreach($lines as $line) {
        $line = addslashes($line);
        $line = explode("\t", $line);
        $classID[$line[0]] = $count;
        $count++;
        $out .= "('".$line[0]."', '".$line[1]."', '".$line[2]."'),\n";
    }
    $out = substr($out, 0, strlen($out)-2).";\n\n";

    DatabaseManager::checkError($out);

   //create ISBN to classID association
    $lines = preg_split("/\r?\n/", $data[0]);
    $lines = array_slice($lines, 1);
    array_pop($lines);
    $lines1 = $lines;
    $count = 1;
    foreach($lines as $line) {
       $line = addslashes($line);
       $line = explode("\t", $line);
       $bookISBN[$line[0]] = $count;
       $count++;
    }

    //class, isbn, verified, comments, usable, uid
    $out = 'INSERT INTO `classbooks` (`classID`, `bookID`, `verified`, `verifiedSemester`, `usable`, `comments`) VALUES'."\n";
    $lines = preg_split("/\r?\n/", $data[2]);
    $lines = array_slice($lines, 7);
    array_pop($lines);
    foreach($lines as $line) {
        $line = addslashes($line);
        $line = explode("\t", $line);
        if($line[4] == "t") {
           $usable = 1;
        } else {
           $usable = 0;
        }
        $isUsable[$line[1]] = $usable;
        $semester = getSemester($semesters[$line[2]]);
        $out .= "('".($classID[$line[0]]+1)."', '".$bookISBN[$line[1]]."', '".$semesters[$line[2]]."', '".$semester."', '".$usable."', '".$line[3]."'),\n";
    }

    $out = substr($out, 0, strlen($out)-2).";\n\n";

    DatabaseManager::checkError($out);

    /*
         db_version - don't care
    */

    //id, name, intertome
    $out = 'INSERT INTO `libraries` (`ID`, `name`, `intertome`) VALUES'."\n";
    $lines = preg_split("/\r?\n/", $data[5]);
    $lines = array_slice($lines, 7);
    array_pop($lines);
    foreach($lines as $line) {
        $line = addslashes($line);
        $line = explode("\t", $line);
        $out .= "('".$line[0]."', '".$line[1]."', 1),\n";
    }

    $out = substr($out, 0, strlen($out)-2).";\n\n";

    DatabaseManager::checkError($out);

    /*
         empty table of useless ?? - don't care
    */

    //id, email, name
    $out = 'INSERT INTO `borrowers` (`ID`, `email`, `name`, `valid`) VALUES'."\n";
    $lines = preg_split("/\r?\n/", $data[8]);
    $lines = array_slice($lines, 7);
    array_pop($lines);
    foreach($lines as $line) {
        $line = addslashes($line);
        $line = explode("\t", $line);
        $out .= "('".$line[0]."', '".$line[1]."', '".$line[2]."', '1'),\n";
    }
    $out = substr($out, 0, strlen($out)-2).";\n\n";

    DatabaseManager::checkError($out);

    /*
         Ignoring all current reservations
    */

    /*
         Ignoring all session data
    */
    //isbn, title, author, edition

    //id, isbn, expire, comments, timedonated, library, timeremoved, originator
    $out = 'INSERT INTO `books` (`ID`, `libraryID`, `bookID`, `donatorID`, `expires`, `expired`, `usable`, `comments`) VALUES'."\n";
    $lines = preg_split("/\r?\n/", $data[12]);
    $lines = array_slice($lines, 7);
    array_pop($lines);
    $bookCount[] = 0;
    $booksLibrary = array();
    foreach($lines as $line) {
        $line = addslashes($line);
        $line = explode("\t", $line);
        if(array_key_exists($line[1], $bookCount) == false) {
           $bookCount[$line[1]] = 0;
           $bookCount[$line[1]]++;
        } else {
           $bookCount[$line[1]]++;
        }
        if($line[2] == '\\\N') {
           $expire = 0;
        } else {
           $expire = $semesters[$line[2]];
        }
        if($line[6] == '\\\N') {
           $expired = 0;
        } else {
           $expired = 1;
        }
        $booksLibrary[$line[0]] = $line[5];
        $out .= "('".$line[0]."', '".$line[5]."', '".$bookISBN[$line[1]]."', '".$line[7]."', '".$expire."', '".$expired."', '".$isUsable[$line[1]]."', '".$line[3]."'),\n";
    }
    $out = substr($out, 0, strlen($out)-2).";\n\n";

    DatabaseManager::checkError($out);

    //isbn, title, author, edition
    $out = 'INSERT INTO `bookTypes` (`title`, `isbn10`, `isbn13`, `author`, `edition`) VALUES'."\n";
    foreach($lines1 as $line) {
        $line = addslashes($line);
        $line = explode("\t", $line);
        if(strlen($line[0]) == 10) {
            $out .= "('".$line[1]."', '".$line[0]."', NULL, '".$line[2]."', '".$line[3]."'),\n";
        } else {
            $out .= "('".$line[1]."', NULL, '".$line[0]."', '".$line[2]."', '".$line[3]."'),\n";
        }
    }
    $out = substr($out, 0, strlen($out)-2).";\n";

    DatabaseManager::checkError($out);

    //uid, library
    $lines = preg_split("/\r?\n/", $data[6]);
    $lines = array_slice($lines, 7);
    array_pop($lines);
    foreach($lines as $line)
    {
        $line = addslashes($line);
        $line = explode("\t", $line);
        $userLib[$line[0]] = $line[1];
    }

    //id, username, email, notifications, admin, password, disabled, first_name, last_name, second_contact, primary_library
    $out = 'INSERT INTO `users` (`username`, `email`, `permissions`, `password`, `active`, `notifications`, `name`, `secondContact`, `libraryID`, `semester`, `firstLogin`) VALUES'."\n";
    $lines = preg_split("/\r?\n/", $data[13]);
    $lines = array_slice($lines, 7);
    array_pop($lines);
    $tomekeeperIDMap = array();
    $tomekeeperLibraryMap = array();
    $result = DatabaseManager::checkError("SELECT max( `ID` ) +1 FROM `users`");
    $tmp = DatabaseManager::fetchArray($result);
    $start = $tmp[0];
    foreach($lines as $line) {
        $line = addslashes($line);
        $line = explode("\t", $line);
        if($line[6] === "f") {
           $active = 1;
        } else {
           $active = 0;
        }
        if($line[3] === "f") {
           $notify = 1;
        } else {
           $notify = 0;
        }
        if($line[10] === "t"){
           $hasLoggedIn = 1;
        } else {
           $hasLoggedIn = 0;
        }
        if(strcmp($line[9], "\\\N") == 0) {
           $secondContact = "";
        } else {
           $secondContact = $line[9];
        }
        $out .= "('".$line[1]."', '".$line[2]."', '3', '".$line[5]."', '".$active."', '".$notify."', '".$line[7]." ".$line[8]."', '"
            .$secondContact."', '".$userLib[$line[0]]."', '2010.25', '".$hasLoggedIn."'),\n";
        $tomekeeperIDMap[$line[0]] = $start++;
        $tomekeeperLibraryMap[$line[0]] = $userLib[$line[0]];
    }
    $out = substr($out, 0, strlen($out)-2).";\n\n";

    DatabaseManager::checkError($out);

    //tomebook, semester, checkout, checkin, comments, library, uid, id, borrower
    $out = 'INSERT INTO `checkouts` (`bookID`, `tomekeeperID`, `libraryToID`, `libraryFromID`, `borrowerID`, `out`, `in`, `semester`, `comments`) VALUES'."\n";
    $lines = preg_split("/\r?\n/", $data[1]);
    $lines = array_slice($lines, 7);
    array_pop($lines);
    foreach($lines as $line) {
        $line = addslashes($line);
        $line = explode("\t", $line);
        $out .= "('".$line[0]."', '".$tomekeeperIDMap[$line[6]]."', '".$tomekeeperLibraryMap[$line[6]]."', '".$booksLibrary[$line[0]]."', '".$line[8]."', '".$line[2]."', '".$line[3]."', '".$semesterF[$line[1]]."', '".$line[4]."'),\n";
    }
    $out = substr($out, 0, strlen($out)-2).";\n\n";

    DatabaseManager::checkError($out);

    //make comments that just have a newline truly empty
    DatabaseManager::checkError("UPDATE `books` SET `comments` = '' WHERE `comments` = '\\N'");
    DatabaseManager::checkError("UPDATE `bookTypes` SET `comments` = '' WHERE `comments` = '\\N'");
    DatabaseManager::checkError("UPDATE `checkouts` SET `comments` = '' WHERE `comments` = '\\N'");
    DatabaseManager::checkError("UPDATE `classbooks` SET `comments` = '' WHERE `comments` = '\\N'");
    DatabaseManager::checkError("UPDATE `classes` SET `comments` = '' WHERE `comments` = '\\N'");

    //update the bookTypeID field on the checkouts table
    $sql = "UPDATE `checkouts` join `books` on `books`.`ID` = `checkouts`.`bookID` SET `checkouts`.`bookTypeID` = `books`.`bookID`";
    DatabaseManager::checkError($sql);

    //put the autoincrements back
    $sql = "ALTER TABLE `books` CHANGE `ID` `ID` INT( 11 ) NOT NULL AUTO_INCREMENT;";
    $sql .= "ALTER TABLE `borrowers` CHANGE `ID` `ID` INT( 11 ) NOT NULL AUTO_INCREMENT ;";
    DatabaseManager::multiCheckError($sql);

    echo "Script Finished!  :-)\n"
?>
