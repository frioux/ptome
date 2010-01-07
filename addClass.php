<?php
    $path = "./";
    $pageTitle = "Add Class";
    require_once($path."header.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Form.php");
    require_once($path."OpenSiteAdmin/scripts/classes/RowManager.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");
    require_once($path."admin/scripts/ClassIDField.php");

    $form = new Form(Form::ADD, $_SERVER["SCRIPT_NAME"]);
    $fieldset = new Fieldset_Vertical($form->getFormType());

    $keyField = $fieldset->addField(new Hidden("ID", "", null, false));
    $linkField = $fieldset->addField(new ClassIDField("class", "ID", array("maxlength"=>8), true, true));
    $fieldset->addField(new Text("name", "Name", array("maxlength"=>100), true, true));

    $row = new RowManager("classes", $keyField->getName());
    $fieldset->addRowManager($row);
    $form->addFieldset($fieldset);
    $form->process();
    if(!empty($_REQUEST["text"])) {
        print $_REQUEST["text"]."<br><br>";
    }
    print '<h1>Add Class</h1>';
    $form->display();
?>
<?php require_once($path."footer.php"); ?>
