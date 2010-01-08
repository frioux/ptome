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
    $id = $_GET["id"];
    $sql = "SELECT `bookTypes`.`ID` AS `bookID`,`bookTypes`.`author`,`bookTypes`.`title`,`bookTypes`.`edition`,`bookTypes`.`isbn10`,`bookTypes`.`isbn13`,`bookTypes`.`comments`
            FROM `bookTypes`
            WHERE `bookTypes`.`ID` = '$id'";
   
    $result = DatabaseManager::checkError($sql);
    if(mysqli_num_rows($result) == 0) {
        print "Unknown bookType ID ".$id;
        require_once($path."footer.php");
        die();
    }
    $book = mysqli_fetch_assoc($result);

    $fieldset = getProcessBookAssociation($book);
    $fieldset2 = getProcessISBNCheckoutFieldset($id, $numBooks);

    $sql = "Select `classes`.`ID`, `classes`.`class`, `classes`.`name` from `classes`
            join `classbooks` on `classes`.`ID` = `classbooks`.`classID`
            where `classbooks`.`bookID` = '".$book["bookID"]."'";
    $result = DatabaseManager::checkError($sql);
    $classes = array();
    while($row = mysqli_fetch_assoc($result)) {
        $classes[] = $row;
    }
?>
<h1>View Book</h1>
<h3>Reserve Book</h3>
<div name="reserve" id="reserve">
    <?php if(!isset($_GET["reserved"])) { ?>
        <form action="" method="post">
            <input type="hidden" name="fieldset<?php print $id; ?>" value="1">
            <?php
                $fieldset2->display();
                if($numBooks > 0) {
                    print '<input name="submit" value="Reserve Book" type="submit">';
                } else {
                    print "There are no books available for this semester. Sorry.";
                }
            ?>
        </form>
    <?php } else { print 'Book Reserved!'; } ?>
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
                <form action="" method="post">
                    <input type="hidden" name="form1" value="1">
                    <?php $fieldset->display(); ?>
                    <input name="submit" value="Associate Class" type="submit">
                </form>
            </td>
        </tr>
    </tbody>
</table>
<?php require_once($path."footer.php"); ?>
