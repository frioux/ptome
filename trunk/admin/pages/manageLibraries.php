<?php
    $path = "../../";
    require_once($path."OpenSiteAdmin/pages/pageHeader.php");

	//SECURITY CHECKING \ REDIRECT CHECKS

	//FUNCTION DEFINITIONS

	//BEGIN TABLE DEFINITION
	$fieldset = new Fieldset_Vertical($form->getFormType());

//    $customSelectOptions = DatabaseManager::checkError("custom database query here");

	$keyField = $fieldset->addField(new Hidden("ID", "", null, false, false));
    $linkField = $fieldset->addField(new Text("name", "Library Name:", array("maxlength"=>50), true, true));
    $fieldset->addField(new Checkbox("interTOME", "InterTOME", null, true, false));
//    $fieldset->addField(new Text(dbTitle, formTitle, options, showInListView?, required?));
    //-- end table definition

	$tableName = "libraries";
	if(!isset($_GET["id"]) || empty($_GET["id"])) {
		$id = -1;
	} else {
		$id = $_GET["id"];
	}
    $id = intval($id);
	$row = new RowManager($tableName, $keyField->getName(), $id);
	$fieldset->addRowManager($row);

	$form->addFieldset($fieldset);

	//CREATE FORM
	$form->process();

	//INCLUDE HEADER FILE
	require_once($path."header.php");

    //custom header html goes here

	//CREATE LIST
	if(empty($_GET["id"]) && $mode != Form::ADD) {
		print $list->generateList($fieldset, $keyField, $linkField, $QS);
	} else {
		$form->display();
	}

    //custom footer html goes here

	//INCLUDE FOOTER FILE
	require_once($path."footer.php");
?>