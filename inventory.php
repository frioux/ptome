<?php
    $path = "./";
    $pageTitle = "Library Inventory";
    require_once($path."admin/scripts/functions.php");
    require_once($path."header.php");

    $libraryID = $_SESSION['libraryID'];

    if(isset($_POST["mode"]) && $_POST["mode"] == "in") {
        $sql = "SELECT `books`.`ID`,
                `bookTypes`.`title`, `bookTypes`.`author`, `bookTypes`.`edition`, `bookTypes`.`isbn10`, `bookTypes`.`isbn13`, `bookTypes`.`ID` AS `bookID`
                FROM `books`
                JOIN `bookTypes` ON `books`.`bookID` = `bookTypes`.`ID`
                WHERE `books`.`libraryID` = '$libraryID' AND `books`.`expired` = '0' AND `books`.`ID` NOT IN (
                    SELECT `bookID`
                    FROM `checkouts`
                    WHERE `libraryFromID` = '$libraryID' AND `in` = DEFAULT(`in`)
                )";
        $title = "These books are currently in your library somewhere";
    } elseif(isset($_POST["mode"]) && $_POST["mode"] == "out") {
        $sql = "SELECT `books`.`ID`, `bookTypes`.`title`, `bookTypes`.`author`, `bookTypes`.`edition`,
                 `bookTypes`.`isbn10`, `bookTypes`.`isbn13`, `bookTypes`.`ID` AS `bookID`
                 FROM `books`
                 JOIN `bookTypes` ON `books`.`bookID` = `bookTypes`.`ID`
                 JOIN `checkouts` ON `books`.`ID` = `checkouts`.`bookID`
                 WHERE `books`.`libraryID` = '$libraryID' AND `books`.`expired`='0' AND `checkouts`.`in` = DEFAULT(`in`)";
        $title = "These books are currently checked out of your library";
    } else {
        $sql = "SELECT `books`.`ID`, `bookTypes`.`title`, `bookTypes`.`author`, `bookTypes`.`edition`,
                 `bookTypes`.`isbn10`, `bookTypes`.`isbn13`, `bookTypes`.`ID` AS `bookID`
                 FROM `books`
                 JOIN `bookTypes` ON `books`.`bookID` = `bookTypes`.`ID`
                 WHERE `books`.`libraryID` = '$libraryID' AND `books`.`expired`='0'";
        $title = "These are all the books your library owns";
        $_POST["mode"] = "all";
    }
    $books = DatabaseManager::fetchAssocArray($sql);
    $_SESSION["post"]["data"] = $books;
    $_SESSION["post"]["name"] = $_POST["mode"];
?>

<h1>Library Inventory</h1>
<form method="post" action="">
    Show: <select name="mode">
        <option value="all"<?php if($_POST["mode"] == "all") print " selected"; ?>>All</option>
        <option value="out"<?php if($_POST["mode"] == "out") print " selected"; ?>>Checked Out</option>
        <option value="in"<?php if($_POST["mode"] == "in") print " selected"; ?>>Checked In</option>
    </select>&nbsp;&nbsp;<input type="submit" name="submit" value="Update">
</form>
<h3 class="print-page-break-before">
    <table class="full">
        <tr>
            <td style="border:0px;">
                <?php print $title." (".count($books).")"; ?>
            </td>
            <td style="text-align:right; border:0px;">
                <span style="font-size:10pt;">
                    <a href="<?php print $path."exportToCSV.php"; ?>">Export to CSV</a>
                </span>
            </td>
        </tr>
    </table>
</h3>

<table class="sortable">
    <thead>
        <tr>
            <th>Title</td>
            <th>Author</td>
            <th>Edition</td>
            <th>ISBN</td>
            <th>ID</td>
        </tr>
    </thead>
    <tbody>
    <?php
        foreach($books as $book) {
            $bookURL = "bookinfo.php?id=".$book["ID"];
            $isbnURL = "isbninfo.php?id=".$book["bookID"];
            $isbn = getISBN($book["isbn13"], $book["isbn10"]);
            print "<tr>
                <td>".$book["title"]."</td>
                <td>".$book["author"]."</td>
                <td>".$book["edition"]."</td>
                <td><a href=$path$isbnURL>$isbn</a></td>
                <td><a href=$path$bookURL>".$book["ID"]."</a></td>
            </tr>";
        }
    ?>
    </tbody>
</table>

<?php require_once($path."footer.php"); ?>
