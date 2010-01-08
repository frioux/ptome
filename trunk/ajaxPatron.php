<?php
    $path = "./";
    $text = current($_POST);
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");
    $sql = "SELECT *
        FROM `borrowers`
        WHERE `email` LIKE '%".$text."%' OR `name` LIKE '%".$text."%' and `valid` = '1'";
    $result = DatabaseManager::checkError($sql);
    print '<ul class="auto_complete_list">';
    if(DatabaseManager::getNumResults($result) > 0) {
        while($row = DatabaseManager::fetchAssoc($result)) {
            print '<li class="auto_complete_item">';
                print '<span class="informal" id="'.$row["ID"].'">';
                    print '<div class="primary">'.$row["name"].'</div>';
                print '</span>';
                print '<div class="secondary">'.$row["email"].'</div>';
            print '</li>';
        }
    }
    print '</ul>';
?>