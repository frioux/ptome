<?php
    $path = "./";
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");

    $sql = "SELECT `users`.`username`, `users`.`email`, `libraries`.`ID`, `libraries`.`name`
            FROM `users`
            JOIN `libraries` on `users`.`libraryID` = `libraries`.`ID`
            WHERE `users`.`active` = '1' AND `users`.`notifications` = '1'";
    $result = DatabaseManager::checkError($sql);
    $libs = array();
    while($row = DatabaseManager::fetchAssoc($result)) {
        $libs[$row["ID"]][] = $row;
    }
    $year = date("Y");
    if(date("j") == 0) {
        if($date("n") == 0) {
            $month = 12;
            $year = date("Y")-1;
        } else {
            $month = date("n")-1;
        }
        $day = date("t", mktime(date("H"), date("i"), date("s"), $month, 1, $year));
    } else {
        $day = date("j")-1;
        $month = date("n");
    }
    //5 minutes and a day ago. Overlap to ensure we don't miss anything.
    $date = date("Y-m-d H:i:s", mktime(date("H"), date("i")-5, date("s"), $month, $day, $year));
    foreach($libs as $lib) {
        //ignore checkouts we made. I hope we already know about those...
        $sql = "SELECT `books`.`ID`,
                `libraries`.`name`,
                `bookTypes`.`title`, `bookTypes`.`author`, `bookTypes`.`edition`,
                `checkouts`.`comments`
                FROM `checkouts`
                JOIN `bookTypes` ON `checkouts`.`bookTypeID` = `bookTypes`.`ID`
                JOIN `books` ON `checkouts`.`bookID` = `books`.`ID`
                JOIN `libraries` ON `checkouts`.`libraryToID` = `libraries`.`ID`
                WHERE `libraryFromID` = '".$lib["ID"]."' AND `libraryToID` != '".$lib["ID"]."' AND `reserved` >= '".$date."'";
        $checkouts = DatabaseManager::fetchAssocArray($sql);
        if(empty($checkouts)) continue;

        $msg = "Hello ".$lib["username"]."! The following books where reserved through interTOME in the last 24 hours.\n";
        $msg .= "ID\tLibrary\tTitle\tAuthor\tEdition\tComments\n";
        foreach($checkouts as $checkout) {
            $msg .= implode("\t", $checkout)."\n";
        }
        $msg .= "\n-TOME Notifier\n\n";
        $msg .= "----------------------------------------\n";
        $msg .= "You are receiving this email because you selected to receive notifications from TOME. If you no longer
wish to receive notifications, edit your preferences <a href='http://localhost/~bion/TOME/management.php'>Here</a>";
        mail($lib["email"], "TOME Notification", $msg, 'From: tome@dorm41.org');
    }
?>