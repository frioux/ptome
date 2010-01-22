<?php
    function getBookAvailability($id) {
        if(!$_SESSION["interTOME"]) {
            $where = "`libraries`.`ID` = '".$_SESSION["libraryID"]."' AND ";
        }
        $sql = "SELECT `libraries`.`ID`, `libraries`.`name`, `libraries`.`interTOME`
                FROM `libraries`
                JOIN `books` ON `books`.`libraryID` = `libraries`.`ID`
                JOIN `bookTypes` ON `books`.`bookID` = `bookTypes`.`ID`
                WHERE ".$where."`bookTypes`.`ID` = '".$id."' and `books`.`expired` = '0' AND `books`.`ID` NOT IN (
                    SELECT `checkouts`.`bookID`
                    FROM `checkouts`
                    WHERE `checkouts`.`bookTypeID` = '".$id."' AND `checkouts`.`in` = DEFAULT(`checkouts`.`in`)
                )";
        //print $sql."<br><br>";
        $result = DatabaseManager::checkError($sql);
        $libBooks = array();
        while($row = DatabaseManager::fetchAssoc($result)) {
            if(!$row["interTOME"]) continue;
            if(!isset($libBooks[$row["ID"]])) {
                $libBooks[$row["ID"]] = $row;
            }
            $libBooks[$row["ID"]]["count"]++;
        }
        $sql = "SELECT count(`ID`) AS `count`, `libraryFromID` from `checkouts` where `bookTypeID`='".$id."' AND `out` = DEFAULT(`out`)";
        //print $sql."<br>=========================<br>";
        $result = DatabaseManager::checkError($sql);
        while($row = DatabaseManager::fetchAssoc($result)) {
            $libBooks[$row["libraryFromID"]]["count"] -= $row["count"];
        }
        foreach($libBooks as $key=>$row) {
            if($row["count"] <= 0) {
                unset($libBooks[$key]);
                continue;
            }
            $libBooks[$key] = $row["name"]." (".$row["count"]." Free)";
        }
        ksort($libBooks);
        return $libBooks;
    }

    function processReserve(Fieldset $fieldset, RowManager $row, Field $linkField, $id, Field $libField=null) {
        if(isset($_REQUEST["submit"]) && $_REQUEST["fieldset".$id]) {
            //Race condition - there aren't even any books left.
            if($libField == null) {
                die(header("Location:".$_SERVER["REQUEST_URI"]."&race=".$id));
            }
            if($fieldset->process()) {
                $result = DatabaseManager::checkError("select `ID` from `borrowers` where `email` = '".$linkField->getValue()."'");
                if(DatabaseManager::getNumResults($result) == 0) {
                    //this patron doesn't exist, so we need to create them.
                    //But, we still want to move this reservations forward.
                    //So, what we'll do is order some Creme Soda for our tomekeeper, and then, while they're distracted,
                    //we run over, save the reservation without a borrowerID, store the table name and primary key in the session
                    //and run away!
                    //It's really brilliant, as long as they like Creme Soda...
                    $storeCreateUser = true;
                    $_SESSION["post"]["email"] = $linkField->getValue();
                    $linkField->setValue(0);
                } else {
                    $tmp = DatabaseManager::fetchAssoc($result);
                    $linkField->setValue($tmp["ID"]);
                }

                //ensure we don't checkout the same book twice.
                //we don't use LOW_PRIORITY here because this is a read heavy app.
                $sql = "LOCK TABLE checkouts AS checkout1 WRITE, checkouts AS checkout2 WRITE, `".$row->getTableName()."` WRITE,
                        `errorLog` WRITE, `books` READ, `bookTypes` READ";
                DatabaseManager::checkError($sql);
                $sql = "SELECT * from `checkouts` AS `checkout1` where `bookTypeID` = '".$id."' AND `libraryFromID` = '".$libField->getValue()."' AND `in` = DEFAULT(`in`)";
                DatabaseManager::checkError($sql);
                $num1 = DatabaseManager::getNumResults();
                $sql = "SELECT `books`.`ID` FROM `books`
                        JOIN `bookTypes` ON `books`.`bookID` = `bookTypes`.`ID`
                        WHERE `books`.`libraryID` = '".$libField->getValue()."' AND `bookTypes`.`ID` = '".$id."' and `books`.`expired` = '0' AND `books`.`ID` NOT IN (
                            SELECT `bookID`
                            FROM `checkouts` AS `checkout2`
                            WHERE `bookTypeID` = '".$id."' AND `in` = DEFAULT(`in`)
                        )";
                DatabaseManager::checkError($sql);
                $num2 = DatabaseManager::getNumResults();
                if($num2-$num1 > 0) {
                    $fieldset->commit();
                } else {
                    die(header("Location:".$_SERVER["REQUEST_URI"]."&race=".$id));
                }
                //release the locks, and we're done.
                DatabaseManager::checkError("UNLOCK TABLES");
                if($storeCreateUser) {
                    $_SESSION["post"]["ID"] = DatabaseManager::getInsertID();
                    $_SESSION["post"]["table"] = "checkouts";
                    $_SESSION["post"]["field"] = "borrowerID";
                    redir_push($_SERVER["REQUEST_URI"]);
                    $_SESSION["post"]["reserveID"] = $id;
                    header("Location:".$path."addPatron.php");
                } else {
                    header("Location:".$_SERVER["REQUEST_URI"]."&reserved=".$id);
                }
            }
        }
    }

    function getISBN($isbn13, $isbn10) {
        return (empty($isbn13)) ? $isbn10 : $isbn13;
    }

    function showBookInfo(array $book, $editable=true, $showID=false) {
        $isbn = getISBN($book["isbn13"], $book["isbn10"]);
        ?>
        <td>
            <dl class="table-display">
                <?php if($showID) { ?>
                    <dt>
                        Book ID
                    </dt>
                    <dd>
                        <a href="<?php print $path."bookinfo.php?id=".$book["ID"]; ?>"><?php print $book["ID"]; ?></a>
                    </dd>
                <?php } ?>
                <dt>
                    ISBN:
                </dt>
                <dd>
                    <a href="<?php print $path."isbninfo.php?id=".$book["bookID"]; ?>"><?php print $isbn; ?></a>
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
            <?php if($editable) { ?>
                <b>Buy it online:</b> <a href="http://isbn.nu/<?php print $isbn; ?>">http://isbn.nu/<?php print $isbn; ?></a>
                <div align="right">
                    <font size="-3">
                        <?php print '<a href="editbooktype.php?id='.$book["bookID"].'&redir='.base64_encode($_SERVER["REQUEST_URI"]).'">Edit</a>'; ?>
                    </font>
                </div>
            <?php } ?>
        </td>
        <?php
    }

    function showCheckoutForm(array $checkout) {
        $books = getAvailableBooksForISBN($checkout["bookID"]);
        ?>
        <div class="print-no" id="checkout<?php print $checkout["ID"]; ?>">
            <form method="post" action="" onsubmit="new Ajax.Updater('checkout<?php print $checkout["ID"]; ?>','reserve.php', {
                                    parameters: Form.serialize(this)+'&id=<?php print $checkout["ID"]; ?>',
                                    onCreate: function(request){$('checkout<?php print $checkout["ID"]; ?>').innerHTML = 'Loading...'},
                                    onSuccess: function(request){new Effect.Highlight( 'checkout<?php print $checkout["ID"]; ?>', { duration:0.5 } )}
                                    }); return false">
                <input type="hidden" value="fill" name="type" id="checkouthidden<?php print $checkout["ID"]; ?>">
                <table class="noborder close">
                    <tbody>
                        <tr>
                            <td>
                                <strong>
                                    Checkout:
                                </strong>
                            </td>
                            <td>
                                <select name="bookID">
                                    <option id="-1">Please select a Book ID</option>
                                    <?php
                                        foreach($books as $b) {
                                            print '<option id="'.$b["ID"].'">'.$b["ID"].'</option>';
                                        }
                                    ?>
                                </select>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <input type="submit" name="submit" value="Cancel" onclick="$('checkouthidden<?php print $checkout["ID"]; ?>').value='cancel';">
                            </td>
                            <td>
                                <input type="submit" name="submit" value="Fill Reservation" onclick="$('checkouthidden<?php print $checkout["ID"]; ?>').value='submit';">
                            </td>
                        </tr>
                    </tbody>
                </table>
            </form>
        </div>
        <?php
    }

    function showCheckinForm(array $book) {
        ?>
        <div class="print-no" id="checkout<?php print $book["checkoutID"]; ?>">
            <input type="submit" name="cancel" value="Cancel" onclick="new Ajax.Updater('checkout<?php print $book["checkoutID"]; ?>','checkin.php', {
                parameters: 'option=cancel&id=<?php print $book["checkoutID"]; ?>'
                })">
            <input type="submit" name="submit" value="Check In" onclick="new Ajax.Updater('checkout<?php print $book["checkoutID"]; ?>','checkin.php', {
                parameters: 'option=return&id=<?php print $book["checkoutID"]; ?>'
                })">
        </div>
        <?php
    }

    function getProcessISBNCheckoutFieldset($bookTypeID, &$numBooks) {
        $libBooks = getBookAvailability($bookTypeID);
        $numBooks = count($libBooks);

        $fieldset = new Fieldset_Vertical(Form::ADD);
        $keyField = $fieldset->addField(new Hidden("ID", "", null, true));
        $linkField = $fieldset->addField(new Text("borrowerID", "Patron", null, true, true));
        $linkField->addAjax(new Ajax_AutoComplete("ajaxPatron.php", 3));
        $fieldset->addField(new Hidden("bookTypeID", "", null, true, true), $bookTypeID);
        $fieldset->addField(new Hidden("tomekeeperID", "", null, false, true), $_SESSION["ID"]);
        $fieldset->addField(new Hidden("semester", "", null, true, true), $_SESSION["semester"]);
        $fieldset->addField(new Hidden("libraryToID", "", null, true, true), $_SESSION["libraryID"]);
        $fieldset->addField(new Hidden("reserved", "", null, true, true), date("Y-m-d H:i:s"));
        $fieldset->addField(new TextArea("comments", "Verification<br>comments", array("rows"=>1, "cols"=>30), false, false));
        $libField = null;
        if(count($libBooks) > 0) {
            $libField = $fieldset->addField(new Select("libraryFromID", "Library", $libBooks, true, true), $_SESSION["libraryID"]);
        }

        $row = new RowManager("checkouts", $keyField->getName());
        $fieldset->addRowManager($row);
        processReserve($fieldset, $row, $linkField, $bookTypeID, $libField);
        return $fieldset;
    }

    function processBookAssociation(Fieldset $fieldset, Field $keyField, Field $linkField, array $book) {
        if(isset($_REQUEST["submit"]) && $_REQUEST["form1"]) {
            //we MUST have at least a seamingly valid class ID before we can move forward
            if($fieldset->process()) {
                $classID = $fieldset->getValue("classID");
                if(empty($classID)) {
                    print '<div class="alert bad">Sorry, the class '.$linkField->getValue().' doesn\'t exist</div>';
                    return;
                } else {
                    $result = DatabaseManager::checkError("select `ID` from `classbooks` where `classID` = '".$classID."' and bookID = '".$book["bookID"]."'");
                    if(DatabaseManager::getNumResults($result) == 0) { //add
                        $fieldset->setFormType(Form::ADD);
                        $row = new RowManager("classbooks", $keyField->getName());
                    } else { //edit
                        $fieldset->setFormType(Form::EDIT);
                        $tmp = DatabaseManager::fetchAssoc($result);
                        $rowID = $tmp["ID"];
                        $row = new RowManager("classbooks", $keyField->getName(), $rowID);
                    }
                    $fieldset->addRowManager($row);
                    //we have a db row now, so we need to reprocess
                    if($fieldset->process()) {
                        $keyField->setValue($rowID);
                        $linkField->setValue($classID);
                        $fieldset->commit();
                        //return those fields to their original states
                        header("Location:".$_SERVER["REQUEST_URI"]);
                    }
                }
            }
        }
    }

    function getProcessBookAssociation(array $book) {
        $fieldset = new Fieldset_Vertical(Form::EDIT);
        $keyField = $fieldset->addField(new Hidden("ID", "", null, true));
        $linkField = $fieldset->addField(new ClassIDField("1", "Class ID", array("maxlength"=>8), true, true));
        $ajax = new Ajax_AutoComplete("ajaxClass.php", 3);
        $ajax->setCallbackFunction("bookCallback".$book["bookID"]);
        $linkField->addAjax($ajax);
        $classIDField = $fieldset->addField(new Hidden("classID", "", null, true, true), 0);
        $classIDField->setCSSID("classID".$book["bookID"]);
        $fieldset->addField(new Hidden("bookID", "", null, true, true), $book["bookID"]);
        $fieldset->addField(new RadioButtons("usable", "Usable", array(1=>"Yes", 0=>"No"), true, false), 1);
        $fieldset->addField(new Hidden("verified", "", null, true, true), date("Y-m-d"));
        $fieldset->addField(new Hidden("verifiedSemester", "", null, true, true), $_SESSION["semester"]);
        $fieldset->addField(new TextArea("comments", "Verification<br>comments", array("rows"=>4, "cols"=>30), false, false));
        processBookAssociation($fieldset, $keyField, $linkField, $book);

        return $fieldset;
    }

    function redir_push($str) {
        if(!is_array($_SESSION["post"]["redir"])) {
            $_SESSION["post"]["redir"] = array();
        }
        array_push($_SESSION["post"]["redir"], $str);
    }

    function redir_pop() {
        return array_pop($_SESSION["post"]["redir"]);
    }

    function cleanSessionOnEmptyRedir() {
        if(empty($_SESSION["post"]["redir"])) {
            unset($_SESSION["post"]);
        }
    }
?>
