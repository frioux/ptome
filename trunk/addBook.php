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
    require_once($path."admin/scripts/functions.php");

    class update_hook implements Hook {
        private $keyField;
        protected $redir;

        function __construct(Field $keyField, $redir) {
            $this->keyField = $keyField;
            $this->redir = $redir;
        }

        function process() {
            $bookID = $_SESSION["post"]["ID"];
            $table = $_SESSION["post"]["table"];
            $field = array_pop($_SESSION["post"]["field"]);
            $row = new RowManager($table, "ID", $bookID);
            $row->setValue($field, $this->keyField->getValue());
            cleanSessionOnEmptyRedir();
            if($row->finalize(Form::EDIT)) {
                die(header("Location:".$this->redir));
            }
        }
    }

    $result = DatabaseManager::checkError("select `name` from `libraries` where `ID` = '".$_SESSION["libraryID"]."'");
    $libraryName = DatabaseManager::fetchAssoc($result);

    $redir = redir_pop();
    $form = new Form(Form::ADD, $redir);
    $form->setSubmitText("Add Book");
    $fieldset = new Fieldset_Vertical($form->getFormType());
    $isbn = $_SESSION["post"]["isbn"];
    if(strlen($isbn) == 13) {
        $isbn13 = $isbn;
    } else {
        $isbn10 = $isbn;
    }

    $keyField = $fieldset->addField(new Hidden("ID", "", null, false));
    if(empty($isbn13)) {
        $field = new ISBNField("isbn13", "ISBN13", 13, true);
    } else {
        $field = new Label("isbn13", "ISBN13", $isbn13, true, true);
    }
    $linkField = $fieldset->addField($field, $isbn13);
    if(empty($isbn10)) {
        $field = new ISBNField("isbn10", "ISBN10", 10, true);
    } else {
        $field = new Label("isbn10", "ISBN10", $isbn10, true, true);
    }
    $fieldset->addField($field, $isbn10);
    $fieldset->addField(new Text("title", "Title", array("maxlength"=>100), true, true));
    $fieldset->addField(new Text("author", "Author", array("maxlength"=>50), true, true));
    $fieldset->addField(new Text("edition", "Edition", array("maxlength"=>20), true, true));

    $row = new RowManager("bookTypes", $keyField->getName());
    $fieldset->addRowManager($row);
    $form->addFieldset($fieldset);
    $hooks[] = new update_hook($keyField, $redir);
    $form->process($hooks);
    redir_push($redir);
?>
<h1>Add Book</h1>
<font size="+1">Adding TOME Book:</font>
<blockquote>
    <b>ISBN:</b> <?php print $isbn; ?><br>
    <b>Originator:</b> <?php print $_SESSION["post"]["email"]; ?><br>
    <b>Expires:</b> <?php print $_SESSION["post"]["expires"]; ?><br>
    <b>Comments:</b> <?php print $_SESSION["post"]["comments"]; ?><br>
    <b>Library:</b> <?php print $libraryName["name"]; ?><br>
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