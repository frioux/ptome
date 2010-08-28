<?php
    require_once($path."OpenSiteAdmin/scripts/classes/Form.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Fieldset.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");
    require_once($path."OpenSiteAdmin/scripts/classes/RowManager.php");
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");

    /**
     * Finds the books that are available to be reserved given a book ID and the session's current semester.
     * NOTE: The checkouts table is referred to by the alias bookAvailabilityCheckouts for the purposes of table locking.
     *
     * A book can be reserved IFF:
     * 1. The book has not expired
     * 2. The book is not checked out this semester and does not have an unreturned checkout from over 2 semesters ago
     * 3. The book does not have a pending reservation for it only for this semester
     * 4. The book is in your library OR (you are a part of interTOME AND interTOME is open)
     *
     * @param INTEGER $id ID number of the specific book.
     * @return ARRAY List of available books of the form books[libraryID]["ID"] - libraryID<br>
     *                  books[libraryID]["name"] - library name<br>
     *                  books[libraryID]["interTOME"] - true if available for intertome loans<br>
     *                  books[libraryID]["count"] - number of available books<br>
     */
    function getBookAvailability($id) {
        //check if interTOME is open
        $sql = "select `interTOME` from `libraries` where `ID` = '3'";
        $result = DatabaseManager::checkError($sql);
        $row = DatabaseManager::fetchArray($result);

        //validate #4
        if(!$_SESSION["interTOME"] || $row[0] == 0) {
            $where = "`libraries`.`ID` = '".$_SESSION["libraryID"]."' AND ";
        }
        //excluding books that are checked out this semester or have not been returned for over 2 semesters
        //validate #1,2
        $sql = "SELECT `libraries`.`ID`, `libraries`.`name`, `libraries`.`interTOME`
                FROM `libraries`
                JOIN `books` ON `books`.`libraryID` = `libraries`.`ID`
                JOIN `bookTypes` ON `books`.`bookID` = `bookTypes`.`ID`
                WHERE ".$where."`bookTypes`.`ID` = '".$id."' and `books`.`expired` = '0' AND `books`.`ID` NOT IN (
                    SELECT bookAvailablityCheckouts.`bookID`
                    FROM `checkouts` AS bookAvailablityCheckouts
                    WHERE bookAvailablityCheckouts.`bookTypeID` = '".$id."' AND bookAvailablityCheckouts.`in` = DEFAULT(bookAvailablityCheckouts.`in`)
                        AND (bookAvailablityCheckouts.`semester` - '".$_SESSION["semester"]."') <= 0.5
                )";
//        print $sql."<br><br>";
        $result = DatabaseManager::checkError($sql);
        $libBooks = array();
        while($row = DatabaseManager::fetchAssoc($result)) {
            if(!$row["interTOME"]) continue;
            if(!isset($libBooks[$row["ID"]])) {
                $libBooks[$row["ID"]] = $row;
            }
            $libBooks[$row["ID"]]["count"]++;
        }
        //excluding books with reservations pending this semester
        //validate #3
        $sql = "SELECT count(`ID`) AS `count`, `libraryFromID` from `checkouts` where `bookTypeID`='".$id."' AND `out` = DEFAULT(`out`) AND `semester` = '".$_SESSION["semester"]."' GROUP BY `libraryFromID`";
        $result = DatabaseManager::checkError($sql);
        while($row = DatabaseManager::fetchAssoc($result)) {
            $libBooks[$row["libraryFromID"]]["count"] -= $row["count"];
        }
        foreach($libBooks as $key=>$row) {
            //remove books with no or negative (what the?) numbers of books
            if($row["count"] <= 0) {
                unset($libBooks[$key]);
                continue;
            }
            $libBooks[$key] = $row["name"]." (".$row["count"]." Free)";
        }
        ksort($libBooks);
        return $libBooks;
    }

    /**
     * Fetch the ISBN number for display, preferring the newer ISBN number.
     *
     * @param STRING $isbn13 ISBN13 number (if any)
     * @param STRING $isbn10 ISBN10 number (if any)
     * @return STRING Preferred ISBN number.
     */
    function getISBN($isbn13, $isbn10) {
        return (empty($isbn13)) ? $isbn10 : $isbn13;
    }

    //display the standard book information table
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

    //Show the checkout form (not reservation, checkout)
    function showCheckoutForm(array $checkout) {
        $books = getAvailableBooksForISBN($checkout["bookID"]);
        ?>
        <?php if(isset($checkout["reserved"])) { ?>
            Reserved: <?php print date('m/d/y', strtotime($checkout["reserved"])); ?>
        <?php } ?>
        <br>
        <div class="print-no" id="checkout<?php print $checkout["checkoutID"]; ?>">
            <form method="post" action="" onsubmit="new Ajax.Updater('checkout<?php print $checkout["checkoutID"]; ?>','reserve.php', {
                                    parameters: Form.serialize(this)+'&id=<?php print $checkout["checkoutID"]; ?>',
                                    onCreate: function(request){$('checkout<?php print $checkout["checkoutID"]; ?>').innerHTML = 'Loading...'},
                                    onSuccess: function(request){new Effect.Highlight( 'checkout<?php print $checkout["checkoutID"]; ?>', { duration:0.5 } )}
                                    }); return false">
                <input type="hidden" value="fill" name="type" id="checkouthidden<?php print $checkout["checkoutID"]; ?>">
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
                                <input type="submit" name="submit" value="Cancel" onclick="$('checkouthidden<?php print $checkout["checkoutID"]; ?>').value='cancel';">
                            </td>
                            <td>
                                <input type="submit" name="submit" value="Fill Reservation" onclick="$('checkouthidden<?php print $checkout["checkoutID"]; ?>').value='submit';">
                            </td>
                        </tr>
                    </tbody>
                </table>
            </form>
        </div>
        <?php
    }

    function getAvailableBooksForISBN($id) {
        $sql = "SELECT `books`.`ID` from `books`
                WHERE `books`.`bookID` = '".$id."' AND `books`.`libraryID` = '".$_SESSION["libraryID"]."' AND `books`.`ID` NOT IN (
                    SELECT `checkouts`.`bookID` from `checkouts`
                    WHERE `checkouts`.`bookTypeID` = '".$id."' AND `checkouts`.`in` = DEFAULT(`checkouts`.`in`) AND `checkouts`.`out` != DEFAULT(`checkouts`.`out`)
                )";
        return DatabaseManager::fetchAssocArray($sql);
    }

    //Show the checkin form
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

    //processes book reservations
    class CheckoutFormHook implements Hook {
        protected $fieldset;
        protected $row;
        protected $linkField;
        protected $patronIDField;
        protected $libField;
        protected $id;

        function __construct(Fieldset $fieldset, RowManager $row, Field $linkField, Field $patronIDField, $id, Field $libField=null) {
            $this->fieldset = $fieldset;
            $this->row = $row;
            $this->linkField = $linkField;
            $this->patronIDField = $patronIDField;
            $this->libField = $libField;
            $this->id = $id;
        }

        function process() {
            //Race condition - there aren't even any books left.
            if($this->libField == null) {
                die(header("Location:".$_SERVER["REQUEST_URI"]."&race=".$this->id));
            }

            //make sure they're actually allowed to check this book out
            //check if interTOME is open
            $sql = "select `interTOME` from `libraries` where `ID` = '3'";
            $result = DatabaseManager::checkError($sql);
            $row = DatabaseManager::fetchArray($result);
            if($_SESSION["libraryID"] != $this->libField->getValue() && (!$_SESSION["interTOME"] || $row[0] == 0)) {
                die(header("Location:".$_SERVER["REQUEST_URI"]));
            }

            $this->fieldset->addRowManager($this->row);
            $this->fieldset->process();
            if($this->patronIDField->isEmpty()) {
                //this patron doesn't exist, so we need to create them.
                //But, we still want to move this reservations forward.
                //So, what we'll do is order some Creme Soda for our tomekeeper, and then, while they're distracted,
                //we run over, save the reservation without a borrowerID, store the table name and primary key in the session
                //and run away!
                //It's really brilliant, as long as they like Creme Soda...
                $storeCreateUser = true;
                $_SESSION["post"]["email"] = $this->linkField->getValue();
            }

            //ensure we don't checkout the same book twice.
            //we don't use LOW_PRIORITY here because this is a read heavy app.
            $sql = "LOCK TABLE checkouts AS bookAvailablityCheckouts READ, libraries READ, `".$this->row->getTableName()."` WRITE,
                    `errorLog` WRITE, `books` READ, `bookTypes` READ";
            DatabaseManager::checkError($sql);
            //finding reservations for the ISBN from this library that have not yet been filled
            $books = getBookAvailability($this->id, "checkouts1");
            if(isset($books[$this->libField->getValue()])) {
                $this->fieldset->commit();
            } else {
                die(header("Location:".$_SERVER["REQUEST_URI"]."&race=".$this->id));
            }
            //release the locks, and we're done.
            DatabaseManager::checkError("UNLOCK TABLES");

            //notify the tomekeeper this book is from of the checkout, if they want the notification
            if($_SESSION["notifications"]) {
                $this->sendNotificationEmail();
            }

            //create the patron if we need to
            if($storeCreateUser) {
                $_SESSION["post"]["ID"] = $this->row->getValue($this->row->getPrimaryKeyName());
                $_SESSION["post"]["table"] = "checkouts";
                $_SESSION["post"]["field"] = "borrowerID";
                redir_push($_SERVER["REQUEST_URI"]);
                $_SESSION["post"]["reserveID"] = $this->id;
                die(header("Location:".$path."addPatron.php"));
            } else {
                die(header("Location:".$_SERVER["REQUEST_URI"]."&reserved=".$this->id));
            }

            return true;
        }

        protected function sendNotificationEmail() {
            $subject = "TOME Notification";
            $headers = "From: noreply@dorm41.org\r\nReply-To: noreply@dorm41.org";

            $libraryID = $this->row->getValue("libraryToID");
            $userID = $this->row->getValue("tomekeeperID");
            $bookID = $this->row->getValue("bookID");
            $checkoutTime = $this->row->getValue("reserved");
            $comments = $this->row->getValue("comments");
            $sql = "SELECT `bookTypes`.`title`, `bookTypes`.`author`, `bookTypes`.`edition`,
                    `libraries`.`name`,
                    `users`.`username`, `users`.`email`
                    FROM `bookTypes`
                    JOIN `libraries` ON `libraries`.`ID` = '".$libraryID."'
                    JOIN `users` ON `users`.`ID` = '".$userID."'
                    WHERE `bookTypes`.`ID`='".$this->id."'";
            $result = DatabaseManager::checkError($sql);
            $info = DatabaseManager::fetchAssoc($result);

            $message = "This is an automated notification that a book has been\nchecked out from your library.\n";
            $message .= "ID: ".$bookID."\n";
            $message .= "Book: ".$info["title"];
            if(!empty($info["edition"])) {
                $message .= ", ".$info["edition"];
            }
            $message .= ": ".$info["author"]."\n\n";
            $message .= "Reserved at ".$checkoutTime." by ".$info["name"]." (".$info["username"].")\n";
            if(!empty($comments)) {
                $message .= $comments;
            }
            $message .= $this->getMessageFooter();

            $email = $info["email"];
//            ErrorLogManager::log(implode("<br>", array($email, $subject, $message, $headers)), ErrorLogManager::INFO);
//            mail($email, $subject, $message, $headers);
        }

        protected function getMessageFooter() {
            $ret = "\n\n-------------------------\n";
            $ret .= "To stop receiving email notifications from TOME,\ngo to dorm41.org/tome/management.php\nand uncheck the 'Notifications' box.";
            return $ret;
        }
    }

    //displays the submit button IFF there are books available to reserve
    class CheckoutForm extends Form {
        protected $hasBooks;

        /**
		 * Constructs a new form manager, which manages all the forms on a page.
		 *
		 * @param INTEGER $type One of the mode constants defined in this class.
		 * @param STRING $redir URL (relative or absolute) to send the user to on successful form processing.
		 * @param STRING $formAction URL (relative or absolute) to submit form data to for processing.
		 */
		function __construct($type, $hasBooks, $redir=null, $formAction="") {
            $this->hasBooks = $hasBooks;
            parent::__construct($type, $redir, $formAction);
        }

        /**
         * Displays the submit button for this form
         *
         * @param BOOLEAN $showUpdate If true, shows an update button
		 * @return VOID
         */
         protected function displaySubmitButton($showUpdate) {
            if($this->hasBooks) {
                parent::displaySubmitButton($showUpdate);
            } else {
                print "There are no books available for this semester. Sorry.";
            }
        }
    }

    //displays and processes the reservation form
    function getProcessISBNCheckoutFieldset($bookTypeID) {
        $libBooks = getBookAvailability($bookTypeID);
        $numBooks = count($libBooks);

        $form = new CheckoutForm(Form::ADD, $numBooks > 0, $_SERVER["REQUEST_URI"]);
        $fieldset = new Fieldset_Vertical($form->getFormType());

        $keyField = $fieldset->addField(new Hidden("ID", "", null, true));
        $patronIDField = $fieldset->addField(new Hidden("borrowerID", "", null, true, true), 0);
        $linkField = $fieldset->addField(new Text("1", "Patron", null, true, true));
        $ajax = new Ajax_AutoComplete("ajaxPatron.php", 3);
        $ajax->setCallbackField($patronIDField);
        $linkField->addAjax($ajax);
        $fieldset->addField(new Hidden("bookTypeID", "", null, true, true), $bookTypeID);
        $fieldset->addField(new Hidden("tomekeeperID", "", null, false, true), $_SESSION["ID"]);
        $fieldset->addField(new Hidden("semester", "", null, true, true), $_SESSION["semester"]);
        $fieldset->addField(new Hidden("libraryToID", "", null, true, true), $_SESSION["libraryID"]);
        $fieldset->addField(new Hidden("reserved", "", null, true, true), date("Y-m-d H:i:s"));
        $fieldset->addField(new TextArea("comments", "Comments", array("rows"=>1, "cols"=>30), false, false));
        $libField = null;
        if($numBooks > 0) {
            $libField = $fieldset->addField(new Select("libraryFromID", "Library", $libBooks, true, true), $_SESSION["libraryID"]);
        }

        $row = new RowManager("checkouts", $keyField->getName());
        //don't add the row to the fieldset. The process hook will take care of that.
        $form->addFieldset($fieldset);
        $form->process(array(new CheckoutFormHook($fieldset, $row, $linkField, $patronIDField, $bookTypeID, $libField)));
        $form->setSubmitText("Reserve Book");
        $form->setAjax("return(copyFirstAutocompleteValue(['".$ajax->getName()."', '".$patronIDField->getCSSID()."']));");

        return $form;
    }

    //Processes associating a book type with a class
    //Decides whether to add a new association entry or edit an existing one
    class ProcessBookAssociationHook implements Hook {
        protected $fieldset;
        protected $keyField;
        protected $linkField;
        protected $book;

        function __construct(Fieldset $fieldset, Field $keyField, Field $linkField, array $book) {
            $this->fieldset = $fieldset;
            $this->keyField = $keyField;
            $this->linkField = $linkField;
            $this->book = $book;
        }

        function process() {
            $classID = $this->fieldset->getValue("classID");
            if(empty($classID)) {
                print '<div class="alert bad">Sorry, the class '.$this->linkField->getValue().' doesn\'t exist</div>';
                return true;
            } else {
                $result = DatabaseManager::checkError("select `ID` from `classbooks` where `classID` = '".$classID."' and bookID = '".$this->book["bookID"]."'");
                if(DatabaseManager::getNumResults($result) == 0) { //add
                    $this->fieldset->setFormType(Form::ADD);
                    $row = new RowManager("classbooks", $this->keyField->getName());
                } else { //edit
                    $this->fieldset->setFormType(Form::EDIT);
                    $tmp = DatabaseManager::fetchAssoc($result);
                    $rowID = $tmp[$this->keyField->getName()];
                    $_POST[$this->keyField->getFieldName()] = $rowID;
                    $row = new RowManager("classbooks", $this->keyField->getName(), $rowID);
                }
                $this->fieldset->addRowManager($row);
                //we have a db row now, so we need to reprocess
                if($this->fieldset->process()) {
                    $this->linkField->setValue($classID);
                    if($this->fieldset->commit()) {
                        //return those fields to their original states
                        die(header("Location:".$_SERVER["REQUEST_URI"]));
                    }
                }
            }
            return false;
        }
    }

    //Displays and processes the form to associate book types to classes
    function getProcessBookAssociation(array $book) {
        $form = new Form(Form::EDIT, $_SERVER["REQUEST_URI"]);
        $fieldset = new Fieldset_Vertical($form->getFormType());

        $keyField = $fieldset->addField(new Hidden("ID", "", null, true));
        $classIDField = $fieldset->addField(new Hidden("classID", "", null, true, true), 0);
        $linkField = $fieldset->addField(new ClassIDField("1", "Class ID", array("maxlength"=>8), true, true));
        $ajax = new Ajax_AutoComplete("ajaxClass.php", 3);
        $ajax->setCallbackField($classIDField);
        $linkField->addAjax($ajax);
        $fieldset->addField(new Hidden("bookID", "", null, true, true), $book["bookID"]);
        $fieldset->addField(new RadioButtons("usable", "Usable", array(1=>"Yes", 0=>"No"), true, false), 1);
        $fieldset->addField(new Hidden("verified", "", null, true, true), date("Y-m-d"));
        $fieldset->addField(new Hidden("verifiedSemester", "", null, true, true), $_SESSION["semester"]);
        $fieldset->addField(new TextArea("comments", "Verification<br>comments", array("rows"=>4, "cols"=>30), false, false));

        $form->addFieldset($fieldset);
        $form->process(array(new ProcessBookAssociationHook($fieldset, $keyField, $classIDField, $book)));
        $form->setSubmitText("Associate Class");
        $form->setAjax("return(copyFirstAutocompleteValue(['".$ajax->getName()."', 'classID".$book["bookID"]."']));");

        return $form;
    }

    //pushes a URL onto the redirection stack. Users are redirected from form submissions
    //based on the contents of this stack
    //WARNING: Most forms statically redirect. Not all forms use the redirect stack!
    function redir_push($str) {
        if(!is_array($_SESSION["post"]["redir"])) {
            $_SESSION["post"]["redir"] = array();
        }
        array_push($_SESSION["post"]["redir"], $str);
    }

    //get the value at the top of the redirect stack
    function redir_pop() {
        return array_pop($_SESSION["post"]["redir"]);
    }

    //cleans up the magic session post data if the redirect stack is empty
    function cleanSessionOnEmptyRedir() {
        if(empty($_SESSION["post"]["redir"])) {
            unset($_SESSION["post"]);
        }
    }
?>
