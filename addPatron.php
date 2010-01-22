<?php
    $path = "./";
    $pageTitle = "Add Patron";
    require_once("header.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Form.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Fieldset.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");
    require_once($path."OpenSiteAdmin/scripts/classes/RowManager.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Hook.php");
    require_once($path."admin/scripts/LETUEmailField.php");
    require_once($path."admin/scripts/functions.php");

    class checkout_update_hoook implements Hook {
        private $keyField;
        protected $redir;

        function __construct(Field $keyField, $redir) {
            $this->keyField = $keyField;
            $this->redir = $redir;
        }

        function process() {
            $checkoutID = $_SESSION["post"]["ID"];
            $table = $_SESSION["post"]["table"];
            $field = array_pop($_SESSION["post"]["field"]);
            $row = new RowManager($table, "ID", $checkoutID);
            $row->setValue($field, $this->keyField->getValue());
            cleanSessionOnEmptyRedir();
            if($row->finalize(Form::EDIT)) {
                die(header("Location:".$this->redir));
            }
        }
    }

    $redir = redir_pop();
    if(isset($_SESSION["post"]["reserveID"])) {
        $redir .= "&reserved=".$_SESSION["post"]["reserveID"];
    }
    $form = new Form(Form::ADD, $redir);
    $fieldset = new Fieldset_Vertical($form->getFormType());

    $keyField = $fieldset->addField(new Hidden("ID", "", null, false));
    $linkField = $fieldset->addField(new LETUEmailField("email", "Email", array("maxlength"=>50), true, true), $_SESSION["post"]["email"]);
    $fieldset->addField(new Text("name", "Name", array("maxlength"=>50), true, true));
    $fieldset->addField(new Hidden("valid", "", null, true, true), 1);

    $row = new RowManager("borrowers", $keyField->getName());
    $fieldset->addRowManager($row);
    $form->addFieldset($fieldset);
    $hooks[] = new checkout_update_hoook($keyField, $redir);
    $form->process($hooks);
    redir_push($redir);
?>
<h1>Add Patron</h1>
<font size="+1" color="red">
    <b><?php print $_SESSION["post"]["email"]; ?></b> is not in the TOME system.
    <br>
    If you are certain that the email address is correct, you may add them by completing this form:
</font>
<br>
<br>
<?php $form->display(); ?>
<?php require_once($path."footer.php"); ?>
