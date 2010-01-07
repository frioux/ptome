<?php
    $path = "./";
    $pageTitle = "Add Book";
    require_once("header.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Form.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Fieldset.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");
    require_once($path."OpenSiteAdmin/scripts/classes/RowManager.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Hook.php");
    require_once($path."admin/scripts/ISBNField.php");

    class update_hook implements Hook {
        private $keyField;
        function __construct(Field $keyField) {
            $this->keyField = $keyField;
        }

        function process() {
            $bookID = $_SESSION["post"]["ID"];
            $row = new RowManager("books", "ID", $bookID);
            $row->setValue("bookID", $this->keyField->getValue());
            $row->finalize(Form::EDIT);
            $redir = $_SESSION["post"]["redir"]."?id=".$bookID;
            unset($_SESSION["post"]);
            die(header("Location:".$redir));
        }
    }

    $form = new Form(Form::ADD, $_SESSION["post"]["redir"]);
    $form->setSubmitText("Add Book");
    $fieldset = new Fieldset_Vertical($form->getFormType());
    $isbn = $_SESSION["post"]["isbn"];
    if(strlen($isbn) == 13) {
        $isbn13 = $isbn;
    } else {
        $isbn10 = $isbn;
    }

    $keyField = $fieldset->addField(new Hidden("ID", "", null, false));
    $linkField = $fieldset->addField(new ISBNField("ISBN13", "ISBN13", 13, true, true), $isbn13);
    $fieldset->addField(new ISBNField("ISBN10", "ISBN10", 10, true, true), $isbn10);
    $fieldset->addField(new Text("title", "Title", array("maxlength"=>100), true, true));
    $fieldset->addField(new Text("author", "Author", array("maxlength"=>50), true, true));
    $fieldset->addField(new Text("edition", "Edition", array("maxlength"=>20), true, true));

    $row = new RowManager("bookTypes", $keyField->getName());
    $fieldset->addRowManager($row);
    $form->addFieldset($fieldset);
    $hooks[] = new update_hook($keyField);
    $form->process($hooks);
?>
<h1>Add Book</h1>
<font size="+1">Adding TOME Book:</font>
<blockquote>
    <b>ISBN:</b> 1111111111<br>
    <b>Originator:</b> jamesfrank@letu.edu<br>
    <b>Expire Semester:</b> 2010, Spring<br>
    <b>Comments:</b> This is a test<br>
    <b>Library:</b> <br>
</blockquote>
<p>
    <font color="red">
        The ISBN you entered is not known by the system.
        <br>
        If you are sure it is correct, please enter the general book information and the book will be added.
    </font>
</p>
<p></p>
<?php $form->display(); ?>
<?php require_once($path."footer.php"); ?>