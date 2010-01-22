<?php
    $path = "./";
    $pageTitle = "Add TOME Book";
    require_once($path."OpenSiteAdmin/scripts/classes/RowManager.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Form.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Fieldset.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Hook.php");
    require_once($path."admin/scripts/ISBNField.php");
    require_once($path."admin/scripts/functions.php");
    require_once($path."header.php");

    Class addBookHook implements Hook {
        const TABLE = "books";
        protected $bookIDField;
        protected $patronIDField;
        protected $ISBNField;
        protected $patronField;

        function __construct(Field $keyField, Field $bookIDField, Field $patronIDField, Field $ISBNField, Field $patronField) {
            $this->keyField = $keyField;
            $this->bookIDField = $bookIDField;
            $this->patronIDField = $patronIDField;
            $this->ISBNField = $ISBNField;
            $this->patronField = $patronField;
        }

        function checkBook() {
            if($this->bookIDField->isEmpty()) {
                $_SESSION["post"]["ID"] = $this->keyField->getValue();
                $_SESSION["post"]["table"] = addBookHook::TABLE;
                array_push($_SESSION["post"]["field"], "bookID");
                $_SESSION["post"]["isbn"] = $this->ISBNField->getValue();
                return false;
            }
            return true;
        }

        function checkPatron() {
            if($this->patronIDField->isEmpty()) {
                $_SESSION["post"]["ID"] = $this->keyField->getValue();
                $_SESSION["post"]["table"] = addBookHook::TABLE;
                array_push($_SESSION["post"]["field"], "donatorID");
                $_SESSION["post"]["email"] = $this->patronField->getValue();
                return false;
            }
            return true;
        }

        function process() {
            $_SESSION["post"]["field"] = array();
            $ret2 = $this->checkPatron();
            $ret1 = $this->checkBook();
            redir_push("bookinfo.php?id=".$this->keyField->getValue());
            if(!$ret1 && !$ret2) {
                //fix the book first
                redir_push("addPatron.php");
                die(header("Location:".$path."addBook.php"));
            } elseif(!$ret1) {
                die(header("Location:".$path."addBook.php"));
            } elseif(!$ret2) {
                die(header("Location:".$path."addPatron.php"));
            } else {
                unset($_SESSION["post"]);
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
    $ajax->setCallbackFunction("bookCallback");
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
    $hooks = array(new addBookHook($keyField, $bookIDField, $donatorIDField, $linkField, $donatorField));
    $form->process($hooks);
    $form->setSubmitText("Add TOME Book");
?>
<h1>Add TOME Book</h1>
<script type="text/javascript">
    <!--
    function bookCallback(element, entry) {
        document.getElementById("<?php print $bookIDField->getFieldName(); ?>").setAttribute("value", entry.children[0].getAttribute("id"));
    }
    function patronCallback(element, entry) {
        document.getElementById("<?php print $donatorIDField->getFieldName(); ?>").setAttribute("value", entry.children[0].getAttribute("id"));
    }
    //-->
</script>
<?php print $form->display(); ?>
<?php require_once($path."footer.php"); ?>
