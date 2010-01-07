<?php
    $path = "./";
    require_once($path."OpenSiteAdmin/scripts/classes/Form.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Fieldset.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");
    require_once($path."OpenSiteAdmin/scripts/classes/RowManager.php");
    require_once($path."admin/scripts/ISBNField.php");
    require_once($path."header.php");

    $id = $_GET["id"];
    $redir = base64_decode($_GET["redir"]);

    $form = new Form(Form::EDIT, $redir);
    $fieldset = new Fieldset_Vertical($form->getFormType());
    $keyField = $fieldset->addField(new Hidden("ID", "", null, false));
    $fieldset->addField(new ISBNField("isbn13", "ISBN13", 13, true, false));
    $fieldset->addField(new ISBNField("isbn10", "ISBN10", 10, true, true));
    $fieldset->addField(new Text("title", "Title", array("maxlength"=>100), true, true));
    $fieldset->addField(new Text("author", "Author", array("maxlength"=>50), true, true));
    $fieldset->addField(new Text("edition", "Edition", array("maxlength"=>20), true, true));
    $fieldset->addField(new TextArea("comments", "Comments", array("rows"=>4, "cols"=>30), false, false));

    $row = new RowManager("bookTypes", $keyField->getName(), $id);
    $fieldset->addRowManager($row);
    $form->addFieldset($fieldset);
    $form->process();

    $form->display();

    require_once($path."footer.php");
?>