<?php
    $path = "./";
    session_start();
    require_once($path."admin/scripts/functions.php");

    $name = $_SESSION["post"]["name"];
    header("content-type:text/csv;");
    header('Content-Disposition: attachment; filename="inventory-'.$name.'.csv"');
    $arr = $_SESSION["post"]["data"];
    $file = fopen("php://output", "w");

    foreach($arr as $line) {
        unset($line["bookID"]);
        $isbn = getISBN($line["isbn13"], $line["isbn10"]);
        $line["isbn"] = $isbn;
        unset($line["isbn13"]);
        unset($line["isbn10"]);
        fputcsv($file, $line);
    }
    fclose($file);
    //unset($_SESSION["post"]);
?>