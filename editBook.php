<?php
    $path = "./";
    require_once($path."OpenSiteAdmin/scripts/classes/Form.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Fieldset.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");
    require_once($path."OpenSiteAdmin/scripts/classes/RowManager.php");

    $id = intval($_REQUEST["id"]);
    $form = new Form(Form::EDIT, $path."bookinfo.php?id=".$id, $path."editBook.php?id=".$id);
    $fieldset = new Fieldset_Vertical($form->getFormType());
    $keyField = $fieldset->addField(new Hidden("ID", "", null, true, true));
    $fieldset->addField(new TextArea("comments", "Comments", array("rows"=>4, "cols"=>30), false, false));
    $fieldset->addField(new Date("expires", "Expire Date", null, true, false));

    $row = new RowManager("books", $keyField->getName(), $id);
    $fieldset->addRowManager($row);
    $form->addFieldset($fieldset);
    $form->process();

    $deleteForm = new Form(Form::DELETE, $path."bookinfo.php?id=".$id, $path."editBook.php?id=".$id);
    $deleteFieldset = new Fieldset_Vertical($deleteForm->getFormType());
    $deleteFieldset->addRowManager($row);
    $deleteForm->addFieldset($deleteFieldset);
    $deleteForm->process();
?>
<div onmouseover="DPC_autoInit()">
    <?php $form->display(); $deleteForm->display(); ?>
</div>