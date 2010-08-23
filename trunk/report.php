<?php
    $path = "./";
    $pageTitle = "Semester Report";
    require_once($path."header.php");
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");
    require_once($path."admin/scripts/functions.php");

    //fetch my TOME reservations
    $sql = "SELECT `checkouts`.`ID`, `checkouts`.`semester`, `checkouts`.`reserved`,
            `borrowers`.`ID` AS `patronID`, `borrowers`.`name`,
            `bookTypes`.`ID` as `bookID`, `bookTypes`.`title`, `bookTypes`.`author`, `bookTypes`.`edition`, `bookTypes`.`isbn13`, `bookTypes`.`isbn10`
            FROM `checkouts`
            JOIN `borrowers` on `checkouts`.`borrowerID` = `borrowers`.`ID`
            JOIN `bookTypes` on `checkouts`.`bookTypeID` = `bookTypes`.`ID`
            WHERE `checkouts`.`libraryToID` = '".$_SESSION["libraryID"]."' AND `checkouts`.`libraryFromID` = '".$_SESSION["libraryID"]."' AND `checkouts`.`out` = DEFAULT(`checkouts`.`out`)";
    $myCheckouts = DatabaseManager::fetchAssocArray($sql);

    //fetch TOME books due back
    $sql = "SELECT `checkouts`.`ID` as `checkoutID`, `checkouts`.`out` , `checkouts`.`semester` ,
            `bookTypes`.`ID` AS `bookID` , `bookTypes`.`author` , `bookTypes`.`title` , `bookTypes`.`edition` , `bookTypes`.`isbn10` , `bookTypes`.`isbn13` ,
            `books`.`ID` ,
            `borrowers`.`ID` AS `patronID` , `borrowers`.`name`
            FROM `checkouts`
            JOIN `bookTypes` ON `checkouts`.`bookTypeID` = `bookTypes`.`ID`
            JOIN `books` ON `checkouts`.`bookID` = `books`.`ID`
            JOIN `borrowers` ON `checkouts`.`borrowerID` = `borrowers`.`ID`
            /*      Check if the book is still out                      Check if we care              Check if we checked this book out                         Check if this book is from our library*/
            WHERE `checkouts`.`in` = DEFAULT(`checkouts`.`in`) AND `books`.`expired` = '0' AND `checkouts`.`libraryToID` = '".$_SESSION["libraryID"]."' AND `checkouts`.`libraryFromID` = '".$_SESSION["libraryID"]."'
            ORDER BY `checkouts`.`semester`";
    $booksDue = DatabaseManager::fetchAssocArray($sql);

    //fetch expiring books
    $sql = "SELECT `bookTypes`.`ID` AS `bookTypeID` , `bookTypes`.`author` , `bookTypes`.`title` , `bookTypes`.`edition` , `bookTypes`.`isbn10` , `bookTypes`.`isbn13` ,
            `books`.`ID` , `books`.`expires` , `books`.`comments` ,
            `borrowers`.`ID` AS `patronID` , `borrowers`.`name`
            FROM `books`
            JOIN `bookTypes` ON `books`.`bookID` = `bookTypes`.`ID`
            JOIN `borrowers` ON `books`.`donatorID` = `borrowers`.`ID`
            WHERE `books`.`libraryID` = '".$_SESSION["libraryID"]."' AND `books`.`expired` = '0' AND `books`.`expires` != DEFAULT(`books`.`expires`) AND DATEDIFF(`books`.`expires`, CURRENT_DATE()) < 100
            ORDER BY `books`.`expires`";
    $booksExpiring = DatabaseManager::fetchAssocArray($sql);

    //fetch my TOME reservations from other floors
    $sql = "SELECT `checkouts`.`ID`, `checkouts`.`semester`, `checkouts`.`reserved`,
            `borrowers`.`ID` AS `patronID`, `borrowers`.`name`,
            `bookTypes`.`ID` as `bookID`, `bookTypes`.`title`, `bookTypes`.`author`, `bookTypes`.`edition`, `bookTypes`.`isbn13`, `bookTypes`.`isbn10`,
            `libraries`.`name` as `libraryName`
            FROM `checkouts`
            JOIN `borrowers` on `checkouts`.`borrowerID` = `borrowers`.`ID`
            JOIN `bookTypes` on `checkouts`.`bookTypeID` = `bookTypes`.`ID`
            JOIN `libraries` on `checkouts`.`libraryFromID` = `libraries`.`ID`
            WHERE `checkouts`.`libraryToID` = '".$_SESSION["libraryID"]."' AND `checkouts`.`libraryFromID` != '".$_SESSION["libraryID"]."' AND `checkouts`.`out` = DEFAULT(`checkouts`.`out`)";
    $myInterTOMECheckouts = DatabaseManager::fetchAssocArray($sql);

    //fetch other floor's TOME reservations from me
    $sql = "SELECT `checkouts`.`ID`, `checkouts`.`semester`,
            `borrowers`.`ID` AS `patronID`, `borrowers`.`name`,
            `bookTypes`.`ID` as `bookID`, `bookTypes`.`title`, `bookTypes`.`author`, `bookTypes`.`edition`, `bookTypes`.`isbn13`, `bookTypes`.`isbn10`,
            `libraries`.`name` as `libraryName`
            FROM `checkouts`
            JOIN `borrowers` on `checkouts`.`borrowerID` = `borrowers`.`ID`
            JOIN `bookTypes` on `checkouts`.`bookTypeID` = `bookTypes`.`ID`
            JOIN `libraries` on `checkouts`.`libraryToID` = `libraries`.`ID`
            WHERE `checkouts`.`libraryToID` != '".$_SESSION["libraryID"]."' AND `checkouts`.`libraryFromID` = '".$_SESSION["libraryID"]."' AND `checkouts`.`out` = DEFAULT(`checkouts`.`out`)";
    $interTOMECheckouts = DatabaseManager::fetchAssocArray($sql);

    //fetch books I need to return to other floors
    $sql = "SELECT `checkouts`.`out` , `checkouts`.`semester` ,
            `bookTypes`.`ID` AS `bookID` , `bookTypes`.`author` , `bookTypes`.`title` , `bookTypes`.`edition` , `bookTypes`.`isbn10` , `bookTypes`.`isbn13` ,
            `books`.`ID` ,
            `borrowers`.`ID` AS `patronID` , `borrowers`.`name`,
            `libraries`.`name` AS `libraryName`
            FROM `checkouts`
            JOIN `bookTypes` ON `checkouts`.`bookTypeID` = `bookTypes`.`ID`
            JOIN `books` ON `checkouts`.`bookID` = `books`.`ID`
            JOIN `borrowers` ON `checkouts`.`borrowerID` = `borrowers`.`ID`
            JOIN `libraries` ON `checkouts`.`libraryFromID` = `libraries`.`ID`
            /*      Check if the book is still out                      Check if we care              Check if we checked this book out                         Check if this book is not from our library*/
            WHERE `checkouts`.`in` = DEFAULT(`checkouts`.`in`) AND `books`.`expired` = '0' AND `checkouts`.`libraryToID` = '".$_SESSION["libraryID"]."' AND `checkouts`.`libraryFromID` != '".$_SESSION["libraryID"]."'
            ORDER BY `checkouts`.`semester`";
    $returnToOthers = DatabaseManager::fetchAssocArray($sql);

    //fetch books that other floors need to return to me
    $sql = "SELECT `checkouts`.`ID` as `checkoutID`, `checkouts`.`out` , `checkouts`.`semester` ,
            `bookTypes`.`ID` AS `bookID` , `bookTypes`.`author` , `bookTypes`.`title` , `bookTypes`.`edition` , `bookTypes`.`isbn10` , `bookTypes`.`isbn13` ,
            `books`.`ID` ,
            `borrowers`.`ID` AS `patronID` , `borrowers`.`name`,
            `libraries`.`name` AS `libraryName`
            FROM `checkouts`
            JOIN `bookTypes` ON `checkouts`.`bookTypeID` = `bookTypes`.`ID`
            JOIN `books` ON `checkouts`.`bookID` = `books`.`ID`
            JOIN `borrowers` ON `checkouts`.`borrowerID` = `borrowers`.`ID`
            JOIN `libraries` ON `checkouts`.`libraryToID` = `libraries`.`ID`
            /*      Check if the book is still out                      Check if we care              Check if we didn't checked this book out                    Check if this book is from our library*/
            WHERE `checkouts`.`in` = DEFAULT(`checkouts`.`in`) AND `books`.`expired` = '0' AND `checkouts`.`libraryToID` != '".$_SESSION["libraryID"]."' AND `checkouts`.`libraryFromID` = '".$_SESSION["libraryID"]."'
            ORDER BY `checkouts`.`semester`";
    $returnToMe = DatabaseManager::fetchAssocArray($sql);
?>
<a name="top"></a>
<h1>Semester Report</h1>
<?php if(count($myCheckouts) > 0) { ?>
    <a href="#reservedMe">TOME Reservations not yet filled (<?php print count($myCheckouts); ?>)</a>
    <br>
<?php } ?>
<?php if(count($booksDue) > 0) { ?>
    <a href="#dueBack">TOME Books due back (<?php print count($booksDue); ?>)</a>
    <br>
<?php } ?>
<?php if(count($booksExpiring) > 0) { ?>
    <a href="#expiring">TOME Books expiring (<?php print count($booksExpiring); ?>)</a>
    <br>
<?php } ?>
<?php if($_SESSION["interTOME"]) { ?>
    <?php if(count($myInterTOMECheckouts) > 0) { ?>
        <a href="#fillForMe">Reservations that need to be filled for me (<?php print count($myInterTOMECheckouts); ?>)</a>
        <br>
    <?php } ?>
    <?php if(count($interTOMECheckouts) > 0) { ?>
        <a href="#fillForOthers">Reservations I need to fill for other floors (<?php print count($interTOMECheckouts); ?>)</a>
        <br>
    <?php } ?>
    <?php if(count($returnToOthers) > 0) { ?>
        <a href="#returnToOthers">Books I need to return to other floors (<?php print count($returnToOthers); ?>)</a>
        <br>
    <?php } ?>
    <?php if(count($returnToMe) > 0) { ?>
        <a href="#returnToMe">Books that other floors need to return to me (<?php print count($returnToMe); ?>)</a>
        <br>
    <?php } ?>
<?php } ?>
<?php if(count($myCheckouts) > 0) { ?>
    <a name="reservedMe"></a>
    <h3 class="print-page-break-before">
        <table class="full">
            <tr>
                <td style="border:0px;">
                    TOME Reservations not yet filled (<?php print count($myCheckouts); ?>)
                </td>
                <td style="text-align:right; border:0px;">
                    <span style="font-size:10pt;">
                        <a href="#top">Top</a>
                    </span>
                </td>
            </tr>
        </table>
    </h3>
    <table class="sortable full" id="sortable-table-0">
        <thead>
            <tr>
                <th class="sortcol">
                    Book
                </th>
                <th class="sortcol">
                    Borrower
                </th>
                <th class="sortcol">
                    Semester
                </th>
                <th class="nosort print-no sortcol">
                    Fill Reservation
                </th>
            </tr>
        </thead>
        <tbody>
            <?php
                foreach($myCheckouts as $checkout) {
                ?>
                <tr class="rowodd">
                    <?php print showBookInfo($checkout, false); ?>
                    <td>
                        <a href="<?php print $path."viewPatron.php?id=".$checkout["patronID"]; ?>"><?php print $checkout["name"]; ?></a>
                    </td>
                    <td>
                        <?php print getSemesterName($checkout["semester"]); ?>
                    </td>
                    <td class="print-no">
                        <?php showCheckoutForm($checkout); ?>
                    </td>
                </tr>
            <?php } ?>
        </tbody>
    </table>
<?php } ?>
<?php if(count($booksDue) > 0) { ?>
    <a name="dueBack"></a>
    <h3 class="print-page-break-before">
        <table class="full">
            <tr>
                <td style="border:0px;">
                    TOME Books due back (<?php print count($booksDue); ?>)
                </td>
                <td style="text-align:right; border:0px;">
                    <span style="font-size:10pt;">
                        <a href="#top">Top</a>
                    </span>
                </td>
            </tr>
        </table>
    </h3>
    <table class="sortable full">
        <thead>
            <tr>
                <th>Book</th>
                <th>Borrower</th>
                <th>Semester</th>
                <th class="nosort print-no" width="110">Check In</th>
            </tr>
        </thead>
        <tbody>
            <?php
                foreach($booksDue as $book) {
                    if($book["semester"] < $_SESSION["semester"]) {
                        print '<tr class="bad">';
                    } else {
                        print '<tr>';
                    }
                ?>
                    <?php print showBookInfo($book, false, true); ?>
                    <td>
                        <a href="<?php print $path."viewPatron.php?id=".$book["patronID"]; ?>"><?php print $book["name"]; ?></a>
                    </td>
                    <td>
                        <?php print getSemesterName($book["semester"]); ?>
                    </td>
                    <td class="print-no">
                        <?php showCheckinForm($book); ?>
                    </td>
                </tr>
            <?php } ?>
        </tbody>
    </table>
<?php } ?>
<?php if(count($booksExpiring) > 0) { ?>
    <a name="expiring"></a>
    <h3 class="print-page-break-before">
        <table class="full">
            <tr>
                <td style="border:0px;">
                    TOME Books expiring (<?php print count($booksExpiring); ?>)
                </td>
                <td style="text-align:right; border:0px;">
                    <span style="font-size:10pt;">
                        <a href="#top">Top</a>
                    </span>
                </td>
            </tr>
        </table>
    </h3>
    <table class="sortable full">
        <thead>
            <tr>
                <th>
                    Book
                </th>
                <th>
                    Originator
                </th>
                <th>
                    Expire
                </th>
                <th>
                    Comments
                </th>
            </tr>
        </thead>
        <tbody>
            <?php
                foreach($booksExpiring as $book) {
                ?>
                <tr>
                    <?php print showBookInfo($book, false, true); ?>
                    <td>
                        <a href="<?php print $path."viewPatron.php?id=".$book["patronID"]; ?>"><?php print $book["name"]; ?></a>
                    </td>
                    <td>
                        <?php print getSemesterName($book["expires"], true); ?>
                    </td>
                    <td>
                        <?php print $book["comments"]; ?>
                    </td>
                </tr>
            <?php } ?>
        </tbody>
    </table>
<?php } ?>
<?php if(count($myInterTOMECheckouts) > 0) { ?>
    <h3 class="print-page-break-before">InterTOME Reservations not yet filled</h3>
    <a name="fillForMe"></a>
    <h4 class="print-page-break-before">
        <table class="full">
            <tr>
                <td style="border:0px;">
                    Reservations that need to be filled for me (<?php print count($myInterTOMECheckouts); ?>)
                </td>
                <td style="text-align:right; border:0px;">
                    <span style="font-size:10pt;">
                        <a href="#top">Top</a>
                    </span>
                </td>
            </tr>
        </table>
    </h4>
    <table class="sortable full" id="sortable-table-3">
        <thead>
            <tr>
                <th class="sortfirstasc text sortcol sortasc">
                    Library
                </th>
                <th class="sortcol">
                    Book
                </th>
                <th class="sortcol">
                    Borrower
                </th>
                <th class="sortcol">
                    Semester
                </th>
                <th class="nosort print-no sortcol">
                    Fill Reservation
                </th>
            </tr>
        </thead>
        <tbody>
            <?php
                foreach($myInterTOMECheckouts as $checkout) {
                ?>
                <tr class="rowodd">
                    <td>
                        <?php print $checkout["libraryName"]; ?>
                    </td>
                    <?php print showBookInfo($checkout, false); ?>
                    <td>
                        <a href="<?php print $path."viewPatron.php?id=".$checkout["patronID"]; ?>"><?php print $checkout["name"]; ?></a>
                    </td>
                    <td>
                        <?php print getSemesterName($checkout["semester"]); ?>
                    </td>
                    <td class="print-no">
                        <div class="print-no" id="checkout<?php print $checkout["ID"]; ?>">
                            <input type="submit" name="cancel" value="Cancel" onclick="new Ajax.Updater('checkout<?php print $checkout["ID"]; ?>','reserve.php', {
                                parameters: 'type=cancel&id=<?php print $checkout["ID"]; ?>'
                                })">
                        </div>
                    </td>
                </tr>
            <?php } ?>
        </tbody>
    </table>
<?php } ?>
<?php if(count($interTOMECheckouts) > 0) { ?>
    <a name="fillForOthers"></a>
    <h4 class="print-page-break-before">
        <table class="full">
            <tr>
                <td style="border:0px;">
                    Reservations I need to fill for other floors (<?php print count($interTOMECheckouts); ?>)
                </td>
                <td style="text-align:right; border:0px;">
                    <span style="font-size:10pt;">
                        <a href="#top">Top</a>
                    </span>
                </td>
            </tr>
        </table>
    </h4>
    <table class="sortable full" id="sortable-table-4">
        <thead>
            <tr>
                <th class="sortfirstasc text sortcol sortasc">
                    Library
                </th>
                <th class="sortcol">
                    Book
                </th>
                <th class="sortcol">
                    Borrower
                </th>
                <th class="sortcol">
                    Semester
                </th>
                <th class="nosort print-no sortcol">
                    Fill Reservation
                </th>
            </tr>
        </thead>
        <tbody>
            <?php
                foreach($interTOMECheckouts as $checkout) {
                ?>
                <tr class="rowodd">
                    <td>
                        <?php print $checkout["libraryName"]; ?>
                    </td>
                    <?php print showBookInfo($checkout, false); ?>
                    <td>
                        <a href="<?php print $path."viewPatron.php?id=".$checkout["patronID"]; ?>"><?php print $checkout["name"]; ?></a>
                    </td>
                    <td>
                        <?php print getSemesterName($checkout["semester"]); ?>
                    </td>
                    <td class="print-no">
                        <?php showCheckoutForm($checkout); ?>
                    </td>
                </tr>
            <?php } ?>
        </tbody>
    </table>
<?php } ?>
<?php if(count($returnToOthers) > 0) { ?>
    <h3 class="print-page-break-before">InterTOME Books due back</h3>
    <a name="returnToOthers"></a>
    <h4 class="print-page-break-before">
        <table class="full">
            <tr>
                <td style="border:0px;">
                    Books I need to return to other floors (<?php print count($returnToOthers); ?>)
                </td>
                <td style="text-align:right; border:0px;">
                    <span style="font-size:10pt;">
                        <a href="#top">Top</a>
                    </span>
                </td>
            </tr>
        </table>
    </h4>
    <table class="sortable full">
        <thead>
            <tr>
                <th class="sortfirstasc text">
                    Library
                </th>
                <th>
                    Book
                </th>
                <th>
                    Borrower
                </th>
                <th class="print-no">
                    Semester
                </th>
            </tr>
        </thead>
        <tbody>
            <?php
                foreach($returnToOthers as $book) {
                    if($book["semester"] < $_SESSION["semester"]) {
                        print '<tr class="bad">';
                    } else {
                        print '<tr>';
                    }
                ?>
                    <td>
                        <?php print $book["libraryName"]; ?>
                    </td>
                    <?php print showBookInfo($book, false, true); ?>
                    <td>
                        <a href="<?php print $path."viewPatron.php?id=".$book["patronID"]; ?>"><?php print $book["name"]; ?></a>
                    </td>
                    <td class="print-no">
                        <?php print getSemesterName($book["semester"]); ?>
                    </td>
                </tr>
            <?php } ?>
        </tbody>
    </table>
<?php } ?>
<?php if(count($returnToMe) > 0) { ?>
    <a name="returnToMe"></a>
    <h4 class="print-page-break-before">
        <table class="full">
            <tr>
                <td style="border:0px;">
                    Books that other floors need to return to me (<?php print count($returnToMe); ?>)
                </td>
                <td style="text-align:right; border:0px;">
                    <span style="font-size:10pt;">
                        <a href="#top">Top</a>
                    </span>
                </td>
            </tr>
        </table>
    </h4>
    <table class="sortable full">
        <thead>
            <tr>
                <th class="sortfirstasc text">
                    Library
                </th>
                <th>
                    Book
                </th>
                <th>
                    Borrower
                </th>
                <th>
                    Semester
                </th>
                <th class="print-no nosort" width="110">
                    Check In
                </th>
            </tr>
        </thead>
        <tbody>
            <?php
                foreach($returnToMe as $book) {
                    if($book["semester"] < $_SESSION["semester"]) {
                        print '<tr class="bad">';
                    } else {
                        print '<tr>';
                    }
                ?>
                    <td>
                        <?php print $book["libraryName"]; ?>
                    </td>
                    <?php print showBookInfo($book, false, true); ?>
                    <td>
                        <a href="<?php print $path."viewPatron.php?id=".$book["patronID"]; ?>"><?php print $book["name"]; ?></a>
                    </td>
                    <td>
                        <?php print getSemesterName($book["semester"]); ?>
                    </td>
                    <td class="print-no">
                        <?php showCheckinForm($book); ?>
                    </td>
                </tr>
            <?php } ?>
        </tbody>
    </table>
<?php } ?>
<?php require_once($path."footer.php"); ?>
