<?php
    $path = "./";
    $text = current($_POST);
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");
    require_once($path."admin/scripts/functions.php");

    $sql = "SELECT `ID`, `isbn10`, `isbn13`, `title`, `edition`
        FROM `bookTypes`
        WHERE `title` LIKE '%".$text."%' OR `isbn10` LIKE '".$text."%' OR `isbn13` LIKE '".$text."%'";
    $result = DatabaseManager::checkError($sql);
    print '<ul class="auto_complete_list">';
    if(DatabaseManager::getNumResults($result) > 0) {
        while($row = DatabaseManager::fetchAssoc($result)) {
            //prefer ISBN 13, but use 10 if that's not available
            $isbn = getISBN($row["isbn13"], $row["isbn10"]);
            print '<li class="auto_complete_item">';
                print '<div class="primary" id="'.$row["ID"].'">'.$isbn.'</div>';
                print '<span class="informal">';
                    print '<div class="secondary">'.$row["title"].': '.$row["edition"].'</div>';
                print '</span>';
            print '</li>';
        }
    }
    print '</ul>';
?>