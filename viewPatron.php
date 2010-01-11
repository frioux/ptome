<?php
    $path = "./";
    $pageTitle = "Patron View";
    require_once($path."header.php");
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Form.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");
    require_once($path."OpenSiteAdmin/scripts/classes/RowManager.php");
    require_once($path."admin/scripts/functions.php");

    $id = explode("?", $_GET["id"]);
    $id = $id[0];
    $form = new Form(Form::EDIT, $_SERVER["SCRIPT_NAME"]."?id=".$id);
    $fieldset = new Fieldset_Vertical($form->getFormType());

    $keyField = $fieldset->addField(new Hidden("ID", "", null, false));
    $linkField = $fieldset->addField(new Text("email", "Email", array("maxlength"=>50), true, true));
    $fieldset->addField(new Text("name", "Display Name", array("maxlength"=>50), true, true));

    $row = new RowManager("borrowers", $keyField->getName(), $id);
    $fieldset->addRowManager($row);
    $form->addFieldset($fieldset);
    $form->process();

    //find books currently checked out
    $sql = "select * from `checkouts` where `borrowerID` = $id and `in` = DEFAULT(`in`)";
    $result = DatabaseManager::checkError($sql);
    $checkedoutCount = DatabaseManager::getNumResults($result);
    $checkouts = DatabaseManager::fetchAssocArray($result);

    //find donations
    $sql = "select * from `books` where `donatorID` = $id";
    $result = DatabaseManager::checkError($sql);
    $donatedCount = DatabaseManager::getNumResults($result);
    $donations = DatabaseManager::fetchAssocArray($result);
?>
<h1>View Patron</h1>
<?php $form->display(); ?>
<h3>Books Checked Out <?php print "($checkedoutCount)"; ?></h3>
<table id="sortable-table-0" class="sortable full">
    <thead>
        <tr>
            <th class="sortcol">
                Library
            </th>
            <th class="sortcol">
                Book
            </th>
            <th class="sortcol">
                Semester
            </th>
            <th class="sortcol">
                Check In
            </th>
        </tr>
    </thead>
    <tbody>
        <?php
        foreach($checkouts as $checkout) {
            $sql = "select `libraries`.`name`,`bookTypes`.* from `books`
                join `libraries` on `libraries`.`ID`=`books`.`libraryID`
                join `bookTypes` on `bookTypes`.`ID`=`books`.`bookID`
                where `books`.`ID` = ".$checkout["bookID"];
            $result = DatabaseManager::checkError($sql);
            $book = DatabaseManager::fetchAssoc($result);
            $book["ID"] = $checkout["ID"];
            $isbn = getISBN($book["isbn13"], $book["isbn10"]);
        ?>
            <tr class="rowodd">
                <td>
                    <?php print $book["name"]; ?>
                </td>
                <td>
                    <dl class="table-display">
                        <dt>
                            Book ID:
                        </dt>
                        <dd>
                            <a href="bookinfo.php?id=<?php print $book["ID"]; ?>"><?php print $book["ID"]; ?></a>
                        </dd>
                        <dt>
                            ISBN:
                        </dt>
                        <dd>
                            <a href="isbninfo.php?id=<?php print $isbn; ?>"><?php print $isbn; ?></a>
                        </dd>
                        <dt>
                            Title:
                        </dt>
                        <dd>
                            <?php print $book["title"]; ?>
                        </dd>
                        <dt>
                            Author:
                        </dt>
                        <dd>
                            <?php print $book["author"]; ?>
                        </dd>
                        <dt>
                            Edition:
                        </dt>
                        <dd>
                            <?php print $book["edition"]; ?>
                        </dd>
                    </dl>
                </td>
                <td>
                    <?php print getSemesterName($checkout["semester"]); ?>
                </td>
                <td>
                    <div class="print-no" name="checkout3113" id="checkout3113">
                        <form action="/cgi-bin/tome/admin.pl" method="post" onsubmit=" new Ajax.Updater( 'checkout3113',  '/cgi-bin/tome/admin.pl', { parameters: Form.serialize(this),asynchronous: 1,onLoading: function(request){$('checkout3113').innerHTML = 'Loading...'
    },onLoaded: function(request){new Effect.Highlight( 'checkout3113', { duration:0.5 } )} } ) ; return false"><input id="checkout_id" name="checkout_id" value="3113" type="hidden">
                            <input id="rm" name="rm" value="ajax_checkin" type="hidden">
                            <input id="ccommit3113" name="commit" value="checkin" type="hidden">
                            <input name="submit" value="Cancel" onclick="$('ccommit3113').value='cancel'; $$('checkout3113 form')[0].submit();" type="submit">
                            <input value="Check In" type="submit">
                        </form>
                    </div>
                </td>
            </tr>
        <?php } ?>
    </tbody>
</table>
<h3 name="books_donated_label" id="books_donated_label">Books Donated <?php print "($donatedCount)"; ?></h3>
<div id="books_donated_table" name="books_donated_table">
    <table class="sortable full">
        <thead>
            <tr>
                <th>
                    Book
                </th>
                <th>
                    Expiration
                </th>
            </tr>
        </thead>
        <tbody>
            <?php
                foreach($donations as $donation) {
                    $sql = "select `bookTypes`.*,`books`.`expires` from `books`
                        join `bookTypes` on `bookTypes`.`ID`=`books`.`bookID`
                        where `books`.`ID` = ".$donation["ID"];
                    $result = DatabaseManager::checkError($sql);
                    $book = DatabaseManager::fetchAssoc($result);
                    $book["ID"] = $donation["ID"];
                    $isbn = getISBN($book["isbn13"], $book["isbn10"]);
            ?>
                <tr>
                    <td>
                        <dl class="table-display">
                            <dt>
                                Book ID:
                            </dt>
                            <dd>
                                <a href="bookinfo.php?id=<?php print $book["ID"]; ?>"><?php print $book["ID"]; ?></a>
                            </dd>
                            <dt>
                                ISBN:
                            </dt>
                            <dd>
                                <a href="isbninfo.php?id=<?php print $isbn; ?>"><?php print $isbn; ?></a>
                            </dd>
                            <dt>
                                Title:
                            </dt>
                            <dd>
                                <?php print $book["title"]; ?>
                            </dd>
                            <dt>
                                Author:
                            </dt>
                            <dd>
                                <?php print $book["author"]; ?>
                            </dd>
                            <dt>
                                Edition:
                            </dt>
                            <dd>
                                <?php print $book["edition"]; ?>
                            </dd>
                        </dl>
                    </td>
                    <td>
                        <?php
                            if($book["expires"] != "0000-00-00") {
                                print getSemesterName($book["expires"], true);
                            }
                        ?>
                    </td>
                </tr>
            <?php } ?>
        </tbody>
    </table>
</div>
<?php require_once($path."footer.php"); ?>
