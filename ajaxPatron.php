<?php
    $path = "./";
    $text = current($_POST);
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");
    $sql = "SELECT *
        FROM `borrowers`
        WHERE `email` LIKE '%".$text."%' OR `name` LIKE '%".$text."%' and `valid` = '1'";
    $result = DatabaseManager::checkError($sql);
    print '<ul class="auto_complete_list">';
    if(mysqli_num_rows($result) > 0) {
        while($row = mysqli_fetch_assoc($result)) {
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