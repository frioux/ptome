<?php
    ob_start();
    $path = "./";
    $pageTitle = "Class Information";
    require_once($path."header.php");
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");
    require_once($path."OpenSiteAdmin/scripts/classes/RowManager.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Form.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Fieldset.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Hook.php");
    require_once($path."admin/scripts/SemesterPicker.php");
    require_once($path."admin/scripts/ISBNField.php");
    require_once($path."admin/scripts/functions.php");

    $id = intval($_REQUEST["id"]);
    if($id == 0) {
        die("Invalid class ID $id<br>");
    }
    $book = new RowManager("classes", "ID", $id);

    $sql = "SELECT `bookTypes`.`ID` as `bookID`, `bookTypes`.`isbn10`, `bookTypes`.`isbn13`, `bookTypes`.`title`, `bookTypes`.`author`, `bookTypes`.`edition`,
            `classbooks`.`comments`, `classbooks`.`verified`, `classbooks`.`usable`, `classbooks`.`ID` as `classbookID`
            FROM `bookTypes`
            JOIN `classbooks` ON `classbooks`.`bookID` = `bookTypes`.`ID`
            WHERE `classbooks`.`classID` = '".$id."'
            ORDER BY `classbooks`.`usable` DESC,`classbooks`.`verifiedSemester` DESC";
    $books = DatabaseManager::fetchAssocArray($sql);
?>
<h1>Class Information</h1>
<h3>Books for <?php print $book->getValue("class").' - '.$book->getValue("name"); ?></h3>
<table class="full">
    <thead>
        <tr>
            <th>Book Info</th>
            <th>Usable Info</th>
            <th>Reservation</th>
        </tr>
    </thead>
    <tbody>
        <?php
        foreach($books as $book) {
            $form3 = getProcessISBNCheckoutFieldset($book["bookID"]);

            $form = new Form(Form::EDIT, $_SERVER["REQUEST_URI"]);
            $form->setSubmitText("Update");
            $fieldset2 = new Fieldset_Vertical($form->getFormType());
            $keyField = $fieldset2->addField(new Hidden("ID", "", null, false));
            $fieldset2->addField(new Select("usable", "Usable", array("1"=>"Yes", "0"=>"No"), true, false));
            $fieldset2->addField(new Hidden("verified", "", null, false, true), date("Y-m-d"));
            $linkField = $fieldset2->addField(new SemesterPicker("verifiedSemester", "Semester", null, true, true));
            $fieldset2->addField(new TextArea("comments", "Comments", array("rows"=>4, "cols"=>15), true, false));

            $row = new RowManager("classbooks", $keyField->getName(), $book["classbookID"]);
            $fieldset2->addRowManager($row);
            $form->addFieldset($fieldset2);
            $form->process();

            $form2 = new Form(Form::DELETE, $_SERVER["REQUEST_URI"]);
            $form2->setSubmitText("Delete");
            $fieldset3 = new Fieldset_Vertical($form2->getFormType());
            $keyField = $fieldset3->addField(new Hidden("ID", "", null, false));
            $row = new RowManager("classbooks", $keyField->getName(), $book["classbookID"]);
            $fieldset3->addRowManager($row);
            $form2->addFieldset($fieldset3);
            $form2->process();

            if($book["usable"]) {
                print '<tr>';
            } else {
                print '<tr bgcolor="lightgrey">';
            }
            ?>
                <?php
                    print showBookInfo($book);
                    if($book["usable"] && getSemesterName($book["verified"], true) == getSemesterName($_SESSION["semester"])) {
                        print '<td class="good">';
                    } else {
                        print '<td>';
                    }
                ?>
                    <?php $form->display(); ?>
                    <div style="position:relative; top:-36px; left:70px;">
                        <?php $form2->display(); ?>
                    </div>
                </td>
                <td>
                    <div>
                        <?php
                            if(isset($_GET["reserved"]) && $_GET["reserved"] == $book["bookID"]) {
                                print 'Book Reserved!';
                            } elseif(isset($_GET["race"]) && $_GET["race"] == $book["bookID"]) {
                                print "Sorry, someone reserved it just before you did...<br>";
                            } else {
                                $form3->display();
                            }
                        ?>
                    </div>
                </td>
            </tr>
        <?php } ?>
    </tbody>
</table>
<?php
    $form = new Form(Form::EDIT, $_SERVER["REQUEST_URI"]);
    $form->setSubmitText("Update");
    $fieldset = new Fieldset_Vertical($form->getFormType());
    $keyField = $fieldset->addField(new Hidden("ID", "", null, false));
    $fieldset->addField(new TextArea("comments", "General Class Comments", array("rows"=>6, "cols"=>80), false, true));
    $row = new RowManager("classes", $keyField->getName(), $id);
    $fieldset->addRowManager($row);
    $form->addFieldset($fieldset);
    $form->process();
?>
<div class="line"></div>
<?php $form->display(); ?>
<div class="line"></div>
<p>
    Add new book for class:
</p>
<?php
    $form = new Form(Form::ADD, $_SERVER["REQUEST_URI"]);
    $fieldset = new Fieldset_Vertical($form->getFormType());
    $keyField = $fieldset->addField(new Hidden("ID", "", null, true));
    $bookIDField = $fieldset->addField(new Hidden("bookID", "", null, true, true));
    $linkField = $fieldset->addField(new ISBNField("1", "ISBN", null, true, true));
    $ajax = new Ajax_AutoComplete("ajaxBook.php", 3);
    $ajax->setCallbackField($bookIDField);
    $linkField->addAjax($ajax);
    $fieldset->addField(new RadioButtons("usable", "Usable", array(1=>"Yes", 0=>"No"), true, false), 1);
    $fieldset->addField(new Hidden("verified", "", null, true, true), date("Y-m-d"));
    $fieldset->addField(new Hidden("verifiedSemester", "", null, true, true), $_SESSION["semester"]);
    $fieldset->addField(new Hidden("classID", "", null, true, true), $id);
    $fieldset->addField(new TextArea("comments", "Verification<br>comments", array("rows"=>4, "cols"=>30), false, false));

    $row = new RowManager("classbooks", $keyField->getName());
    $fieldset->addRowManager($row);
    $form->addFieldset($fieldset);
    $form->process();
    $form->setSubmitText("Update");
    $form->setAjax("return(copyFirstAutocompleteValue(['".$ajax->getName()."', '".$bookIDField->getCSSID()."']));");

    $form->display();
?>
<div class="line"></div>
<?php
    class DeleteClassHook implements Hook {
        private $id;
        function __construct($id) {
            $this->id = $id;
        }

        function process() {
            $sql = "DELETE FROM `classbooks` WHERE `classbooks`.`classID` = '".$id."'";
            return DatabaseManager::checkError($sql);
        }
    }

    $form = new Form(Form::DELETE, $path);
    $form->setSubmitText("Delete");
    $fieldset = new Fieldset_Vertical($form->getFormType());
    $keyField = $fieldset->addField(new Hidden("ID", "", null, false));
    $row = new RowManager("classes", $keyField->getName(), $id);
    $fieldset->addRowManager($row);
    $form->addFieldset($fieldset);
    $form->process(array(new DeleteClassHook($id)));
?>
<p>
    Delete class and all book associations:
</p>
<?php $form->display(); ?>
<?php require_once($path."footer.php"); ?>
