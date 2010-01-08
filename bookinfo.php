<?php
    $path = "./";
    $pageTitle = "Book Info";
    require_once($path."header.php");
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Form.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");
    require_once($path."OpenSiteAdmin/scripts/classes/RowManager.php");
    require_once($path."admin/scripts/ClassIDField.php");
    require_once($path."admin/scripts/functions.php");

    if(!isset($_GET["id"])) {
        die("No book ID provided<br>");
    }
    //get the book info
    $id = $_GET["id"];
    $sql = "SELECT `books`.`ID`,`books`.`expires`,`books`.`expired`,`books`.`comments`,`books`.`donatorID`,
            `libraries`.`name` AS `library` ,
            `bookTypes`.`ID` AS `bookID`,`bookTypes`.`author`,`bookTypes`.`title`,`bookTypes`.`edition`,`bookTypes`.`isbn10`,`bookTypes`.`isbn13`,`bookTypes`.`comments` AS `bookComments`,
            borrowers.`name`
            FROM `books`
            JOIN `libraries` ON `books`.`libraryID` = `libraries`.`ID`
            JOIN `bookTypes` ON `books`.`bookID` = `bookTypes`.`ID`
            JOIN `borrowers` ON `books`.`donatorID` = `borrowers`.`ID`
            WHERE `books`.`ID` = '$id'";
    $result = DatabaseManager::checkError($sql);
    if(DatabaseManager::getNumResults($result) == 0) {
        print 'Unable to find TOME book with ID "'.$id.'"';
        require_once($path."footer.php");
        die();
    }
    $book = DatabaseManager::fetchAssoc($result);

    //get previous checkout info
    $sql = "select `checkouts`.* , `libraries`.`name`
            FROM `checkouts`
            JOIN `users` ON `checkouts`.`tomekeeperID` = `users`.`ID`
            JOIN `libraries` ON `users`.`libraryID` = `libraries`.`ID`
            where `bookID` = '".$book["ID"]."' order by `out` DESC";
    $checkouts = DatabaseManager::fetchAssocArray($sql);

    $fieldset = getProcessBookAssociation($book);

    $sql = "Select `classes`.`ID`, `classes`.`class`, `classes`.`name` from `classes`
            join `classbooks` on `classes`.`ID` = `classbooks`.`classID`
            where `classbooks`.`bookID` = '".$book["bookID"]."'";
    $classes = DatabaseManager::fetchAssocArray($sql);
?>
<h1>TOME Book Info</h1>
<h3>Book #<?php print $book["ID"]; ?></h3>
<?php if($book["expired"]) { ?>
    <div class="alert bad">Book has been removed from TOME</div>
<?php } ?>
<table class="full" bgcolor="lightyellow">
    <thead>
        <tr>
            <th>Book Information</th>
            <th>Used in these classes</th>
            <th>Associate Class</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <?php showBookInfo($book); ?>
            <td>
                <?php
                    foreach($classes as $class) {
                        print '<a href="viewClass.php?id='.$class["ID"].'">'.$class["class"].'</a> - '.$class["name"];
                        print '<br>';
                    }
                ?>
                <br>
            </td>
            <td>
                <script type="text/javascript">
                    <!--
                    function bookCallback<?php print $book["bookID"]; ?>(element, entry) {
                        document.getElementById("classID<?php print $book["bookID"]; ?>").setAttribute("value", entry.children[0].getAttribute("id"));
                    }
                    //-->
                </script>
                <form action="" method="post">
                    <input type="hidden" name="form1" value="1">
                    <?php $fieldset->display(); ?>
                    <input name="submit" value="Associate Class" type="submit">
                </form>
            </td>
        </tr>
    </tbody>
</table>
<strong>Library:</strong> <?php print $book["library"]; ?>
<br>
<strong>Originator:</strong> <a href="viewPatron.php?id=<?php print $book["donatorID"]; ?>"><?php print $book["name"]; ?></a>
<br>
<strong>Comments:</strong>
<?php
    $comments = $book["comments"];
    if(!empty($comments)) {
        $comments .= "<br><br>";
    }
    $comments .= $book["bookComments"];
    print '<blockquote>'.$comments.'</blockquote>';
?>
<strong>Expiration Semester:</strong>
<?php
    if($book["expires"] == "0000-00-00") {
        print '<font color="green">This book will not expire</font>';
    } else {
        print getSemesterName($book["expires"], true);
    }
?>
<br>
<p>
    <div class="print-no" id="editBook">
        <a onclick="new Ajax.Updater('editBook','editBook.php', {parameters: 'id=<?php print $id; ?>'})">Edit this TOME book</a>
    </div>
    <a name="checkout"></a>
</p>
<h4>Checkout:</h4>
<strong>Books can only be checked out through a reservation.  Use <a href="isbninfo.php?id=<?php print $bookType["ID"]; ?>">ISBN page</a> if you want to check out a book.</strong>
<br>
<h4>Checkout History</h4>
<?php
    if(empty($checkouts)) {
        print 'No history';
    } else {
?>
    <table>
        <thead>
            <tr>
                <th>
                    Semester
                </th>
                <th>
                    Borrower
                </th>
                <th>
                    Library
                </th>
                <th>
                    Checked Out
                </th>
                <th>
                    Checkin
                </th>
            </tr>
        </thead>
        <tbody>
            <?php foreach($checkouts as $checkout) { ?>
                <tr>
                    <td>
                        <?php print getSemesterName($checkout["semester"]); ?>
                    </td>
                    <td>
                        <?php
                            //get the borrower's name
                            $result = DatabaseManager::checkError("select `name` from `borrowers` where `ID` = ".$checkout["borrowerID"]);
                            $name = DatabaseManager::fetchAssoc($result);
                            $name = $name["name"];
                        ?>
                        <a href="viewPatron.php?id=<?php print $checkout["borrowerID"]; ?>"><?php print $name; ?></a>
                    </td>
                    <td>
                        <?php print $checkout["name"]; ?>
                    </td>
                    <td>
                        <?php print dateFromMySQL($checkout["out"]); ?>
                    </td>
                    <td>
                        <?php
                            if($checkout["in"] != "0000-00-00 00:00:00") {
                                print dateFromMySQL($checkout["in"]);
                            } else { ?>
                            <div class="print-no" name="checkout3667" id="checkout3667">
                                <form action="/cgi-bin/tome/admin.pl" method="post" onsubmit=" new Ajax.Updater( 'checkout3667',  '/cgi-bin/tome/admin.pl', { parameters: Form.serialize(this),asynchronous: 1,onLoading: function(request){$('checkout3667').innerHTML = 'Loading...'
            },onLoaded: function(request){new Effect.Highlight( 'checkout3667', { duration:0.5 } )} } ) ; return false"><input id="checkout_id" name="checkout_id" value="3667" type="hidden">
                                    <input id="rm" name="rm" value="ajax_checkin" type="hidden">
                                    <input id="ccommit3667" name="commit" value="checkin" type="hidden">
                                    <input name="submit" value="Cancel" onclick="$('ccommit3667').value='cancel'; $$('checkout3667 form')[0].submit();" type="submit">
                                    <input value="Check In" type="submit">
                                </form>
                            </div>
                        <?php } ?>
                    </td>
                </tr>
            <?php } ?>
        </tbody>
    </table>
<?php } ?>
<?php require_once($path."footer.php"); ?>
