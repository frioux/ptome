<?php
    $path = "./";
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");

    $id = $_POST["id"];
    $now = date("Y-m-d H:i:s");
    if($_POST["type"] == "cancel") {
        $sql = "DELETE FROM `checkouts` WHERE `ID`='$id'";
        if(!DatabaseManager::checkError($sql)) {
            Print "ERROR!";
        } else {
            print "Canceled!";
        }
    } elseif($_POST["type"] == "submit") {
        $bookID = $_POST["bookID"];
        if(!is_numeric($bookID)) {
            die("Please select a book");
        }
        $sql = "UPDATE `checkouts` SET `bookID` = '$bookID', `out` = '$now' WHERE `ID`='$id'";
        if(!DatabaseManager::checkError($sql)) {
            Print "ERROR!";
        } else {
            print "Checked Out!";
        }
    } else {
        die("I don't know what you did,<br>but please don't do it again...");
    }
?>