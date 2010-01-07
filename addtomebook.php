<?php
    $path = "./";
    $pageTitle = "Add TOME Book";
    require_once($path."OpenSiteAdmin/scripts/classes/RowManager.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Form.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Fieldset.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Hook.php");
    require_once($path."admin/scripts/ISBNField.php");
    require_once($path."header.php");

    Class addBookHook implements Hook {
        protected $field;

        function __construct(Field $keyField, Field $field) {
            $this->keyField = $keyField;
            $this->field = $field;
        }

        function process() {
            $result = DatabaseManager::checkError("select `ID` from `bookTypes` where `isbn10` LIKE '%".$this->field->getValue()."%' OR `isbn13` LIKE '%".$this->field->getValue()."%'");
            if(mysqli_num_rows($result) == 0) {
                $row = mysqli_fetch_assoc($result);
                $_SESSION["post"]["ID"] = $this->keyField->getValue();
                $_SESSION["post"]["redir"] = "bookinfo.php";
                $_SESSION["post"]["isbn"] = $this->field->getValue();
                die(header("Location:".$path."addBook.php"));
            } else {
                die(header("Location:bookinfo.php?id=".$this->keyField->getValue()));
            }
        }
    }

    $form = new Form(Form::ADD, $_SERVER["REQUEST_URI"]);
    $fieldset = new Fieldset_Vertical($form->getFormType());

    $keyField = $fieldset->addField(new Hidden("ID", "", null, false));
    $fieldset->addField(new Hidden("libraryID", "", null, true, true), $_SESSION["libraryID"]);
    $bookIDField = $fieldset->addField(new Hidden("bookID", "", null, false, true), 0);
    $linkField = $fieldset->addField(new ISBNFIeld("1", "ISBN", null, true, true));
    $ajax = new Ajax_AutoComplete("ajaxBook.php", 3);
    $ajax->setCallbackFunction("classCallback");
    $linkField->addAjax($ajax);
    $donatorIDField = $fieldset->addField(new Hidden("donatorID", "", null, false, true));
    $donatorField = $fieldset->addField(new Text("2", "Originator", null, true, true));
    $ajax = new Ajax_AutoComplete("ajaxPatron.php", 3);
    $ajax->setCallbackFunction("patronCallback");
    $donatorField->addAjax($ajax);
    $fieldset->addField(new Date("expires", "Expire Date", null, true, false));
    $fieldset->addField(new TextArea("comments", "Comments", array("rows"=>2, "cols"=>30), false));

    $row = new RowManager("books", $keyField->getName());
    $fieldset->addRowManager($row);
    $form->addFieldset($fieldset);
    $hooks = array(new addBookHook($keyField, $linkField));
    $form->process($hooks);
    $form->setSubmitText("Add TOME Book");
?>
<h1>Add TOME Book</h1>
<script type="text/javascript">
    <!--
    function classCallback(element, entry) {
        document.getElementById("<?php print $bookIDField->getFieldName(); ?>").setAttribute("value", entry.children[0].getAttribute("id"));
    }
    function patronCallback(element, entry) {
        document.getElementById("<?php print $donatorIDField->getFieldName(); ?>").setAttribute("value", entry.children[0].getAttribute("id"));
    }
    //-->
</script>
<?php print $form->display(); ?>
<?php require_once($path."footer.php"); ?>
