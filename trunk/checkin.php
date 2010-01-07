<?php
    $path = "./";
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");

    $id = $_POST["id"];
    $now = date("Y-m-d H:i:s");
    if($_POST["option"] == "cancel") {
        $sql = "UPDATE `checkouts` SET `in` = '$now', `comments` = CONCAT(`comments`, '\nCancelled!') WHERE `ID`='$id'";
        if(!DatabaseManager::checkError($sql)) {
            Print "ERROR!";
        } else {
            print "Canceled!";
        }
    } else {
        $sql = "UPDATE `checkouts` SET `in` = '$now' WHERE `ID`='$id'";
        if(!DatabaseManager::checkError($sql)) {
            Print "ERROR!";
        } else {
            print "Checked In!";
        }
    }
?>