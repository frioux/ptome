<?php
    $path = "./";
    $text = current($_POST);
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");
    $sql = "SELECT *
        FROM `classes`
        WHERE `class` LIKE '%".$text."%' OR `name` LIKE '%".$text."%'";
    $result = DatabaseManager::checkError($sql);
    print '<ul class="auto_complete_list">';
    if(mysqli_num_rows($result) > 0) {
        while($row = mysqli_fetch_assoc($result)) {
            print '<li class="auto_complete_item">';
                print '<div class="primary" id="'.$row["ID"].'">'.$row["class"].'</div>';
                print '<span class="informal">';
                    print '<div class="secondary">'.$row["name"].'</div>';
                print '</span>';
            print '</li>';
        }
    }
    print '</ul>';
?>