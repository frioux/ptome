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
        protected $fields;

        function __construct(array $fields) {
            $this->fields = $fields;
        }

        function get($field) {
            return $this->fields[$field]->getValue();
        }

        function checkBook() {
            if($this->fields["bookID"]->isEmpty()) {
                $_SESSION["post"]["ID"] = $this->get("ID");
                $_SESSION["post"]["table"] = addBookHook::TABLE;
                array_push($_SESSION["post"]["field"], "bookID");
                $_SESSION["post"]["isbn"] = $this->get("1");
                $_SESSION["post"]["email"] = $this->get("2");
                $_SESSION["post"]["expires"] = $this->get("expires");
                $_SESSION["post"]["comments"] = $this->get("comments");
                return false;
            }
            return true;
        }

        function checkPatron() {
            if($this->fields["donatorID"]->isEmpty()) {
                $_SESSION["post"]["ID"] = $this->get("ID");
                $_SESSION["post"]["table"] = addBookHook::TABLE;
                array_push($_SESSION["post"]["field"], "donatorID");
                $_SESSION["post"]["email"] = $this->get("2");
                return false;
            }
            return true;
        }

        function process() {
            $_SESSION["post"]["field"] = array();
            $ret2 = $this->checkPatron();
            $ret1 = $this->checkBook();
            redir_push("bookinfo.php?id=".$this->get("ID"));
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
                die(header("Location:bookinfo.php?id=".$this->get("ID")));
            }
        }
    }

    $form = new Form(Form::ADD, $_SERVER["REQUEST_URI"]);
    $fieldset = new Fieldset_Vertical($form->getFormType());

    $keyField = $fieldset->addField(new Hidden("ID", "", null, false));
    $fieldset->addField(new Hidden("libraryID", "", null, true, true), $_SESSION["libraryID"]);
    $bookIDField = $fieldset->addField(new Hidden("bookID", "", null, false, true), 0);
    $linkField = $fieldset->addField(new ISBNFIeld("1", "ISBN", null, true, true));
    $ajax1 = new Ajax_AutoComplete("ajaxBook.php", 3);
    $ajax1->setCallbackField($bookIDField);
    $linkField->addAjax($ajax1);
    $donatorIDField = $fieldset->addField(new Hidden("donatorID", "", null, false, true));
    $donatorField = $fieldset->addField(new Text("2", "Originator", null, true, true));
    $ajax2 = new Ajax_AutoComplete("ajaxPatron.php", 3);
    $ajax2->setCallbackField($donatorIDField);
    $donatorField->addAjax($ajax2);
    $fieldset->addField(new Date("expires", "Expire Date", null, true, false));
    $fieldset->addField(new TextArea("comments", "Comments", array("rows"=>2, "cols"=>30), false));

    $row = new RowManager("books", $keyField->getName());
    $fieldset->addRowManager($row);
    $form->addFieldset($fieldset);
    $hooks = array(new addBookHook($fieldset->getFields()));
    $form->process($hooks);
    $form->setSubmitText("Add TOME Book");
    $form->setAjax("return(copyFirstAutocompleteValue(['".$ajax1->getName()."', '".$bookIDField->getCSSID()."', '".$ajax2->getName()."', '".$donatorIDField->getCSSID()."']));");
?>
<h1>Add TOME Book</h1>
<?php print $form->display(); ?>
<?php require_once($path."footer.php"); ?>
