<?php
    $path = "./";
    $pageTitle = "ISBN Info";
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
    $id = intval($_GET["id"]);
    $sql = "SELECT `bookTypes`.`ID` AS `bookID`,`bookTypes`.`author`,`bookTypes`.`title`,`bookTypes`.`edition`,`bookTypes`.`isbn10`,`bookTypes`.`isbn13`,`bookTypes`.`comments`
            FROM `bookTypes`
            WHERE `bookTypes`.`ID` = '$id'";

    $result = DatabaseManager::checkError($sql);
    if(DatabaseManager::getNumResults($result) == 0) {
        print "Unknown bookType ID ".$id;
        require_once($path."footer.php");
        die();
    }
    $book = DatabaseManager::fetchAssoc($result);

    $form = getProcessBookAssociation($book);
    $form2 = getProcessISBNCheckoutFieldset($id);

    $sql = "Select `classes`.`ID`, `classes`.`class`, `classes`.`name` from `classes`
            join `classbooks` on `classes`.`ID` = `classbooks`.`classID`
            where `classbooks`.`bookID` = '".$book["bookID"]."' AND `classbooks`.`usable` = '1'";
    $classes = DatabaseManager::fetchAssocArray($sql);
?>
<h1>View Book</h1>
<h3>Reserve Book</h3>
<div name="reserve" id="reserve">
    <?php
        if(!isset($_GET["reserved"]) && !isset($_GET["race"])) {
            $form2->display();
        } elseif(!isset($_GET["race"])) {
            print 'Book Reserved!';
        } else {
            print "Sorry, someone reserved it just before you did...<br>";
        }
    ?>
</div>
<br>
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
                    new Ajax.Autocompleter( 'isbn', 'isbn_auto_complete', 'ajaxBook.php', {frequency:0.2, minChars:3, afterUpdateElement:isbnCallback} )
                    //-->
                </script>
                <?php $form->display(); ?>
            </td>
        </tr>
    </tbody>
</table>
<?php require_once($path."footer.php"); ?>
